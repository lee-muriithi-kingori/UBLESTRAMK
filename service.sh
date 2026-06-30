#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Script (Late Start)
# Main hiding logic - runs after boot completes
#
# CHANGES (v1.2.0):
# - ADDED boot verification system (check post-fs-data completion)
# - ADDED boot failure tracking and recovery mechanism
# - ADDED safe mode detection and reduced activity mode
# - ADDED community channel reference in logs
# - ADDED verify_boot function for self-test
# - ADDED network-aware keybox update (waits for network)
# - ADDED post-fs-data completion monitoring
# - Fixed keybox_updater to wait for network availability
#
# CHANGES (v1.1.0):
# - Added keybox_updater.sh periodic check integration
# - Added webui configuration initialization
# - Enhanced keybox auto-update in monitor loop
#
# CHANGES (v1.0.0):
# - Added keybox/keystore early property spoofing
# - Enhanced monitor loop with keybox attestation support
#
# CHANGES (audit-fixes):
# - Removed duplicate property sets
# - Replaced 'disown' bashism with POSIX-compatible nohup subshell
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

# v1.2.0: Start boot verification timing
BOOT_START_TIME=$(date +%s 2>/dev/null || echo 0)

log_msg "INFO" "=== UBLESTRAMK service starting ==="
log_msg "INFO" "Version: $(get_version)"
log_msg "INFO" "Root solution: $(detect_root_solution)"
log_msg "INFO" "Community: https://t.me/lestramk"
log_msg "INFO" "Issues: https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues"

# v1.2.0: Boot verification - check if post-fs-data completed successfully
if [ -f "$MODPATH/.post_fs_data_done" ]; then
    PFS_STATUS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
    if [ "$PFS_STATUS" = "1" ]; then
        log_msg "INFO" "Boot verification: post-fs-data completed successfully"
    else
        log_msg "WARN" "Boot verification: post-fs-data may not have completed correctly"
    fi
else
    log_msg "WARN" "Boot verification: post-fs-data marker not found - creating now"
    echo "0" > "$MODPATH/.post_fs_data_done" 2>/dev/null || true
fi

# v1.2.0: Check for safe mode flag from post-fs-data
if [ -f "$MODPATH/.safe_mode_detected" ]; then
    log_msg "INFO" "Safe mode detected - running minimal service"
    sleep 30
    echo "0" > "$MODPATH/.boot_verified" 2>/dev/null || true
    exit 0
fi

# v1.1.0: Initialize webui configuration
if [ -f "$MODPATH/update_service_addon.sh" ]; then
    . "$MODPATH/update_service_addon.sh"
    ensure_webui_config
    log_msg "INFO" "WebUI configuration initialized"
    log_msg "INFO" "WebUI available at: KernelSU Manager > Modules > UBLESTRAMK"
fi

# Apply initial bootloader spoof on boot
spoof_bootloader_locked
hide_build_properties

# v1.2.0: Background worker - late-boot properties with boot verification
(
    sleep 10
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    resetprop_if_diff sys.oem_unlock_allowed 0
    if [ "$SKIPDELPROP" = false ]; then
        delprop_if_exist ro.build.selinux
    fi
    
    # v1.2.0: Mark late-boot properties as applied
    log_msg "INFO" "Late-boot properties applied"
    
    # v1.2.0: If boot is completed, mark as verified
    if is_boot_completed; then
        echo "1" > "$MODPATH/.boot_verified" 2>/dev/null || true
        BOOT_END_TIME=$(date +%s 2>/dev/null || echo 0)
        BOOT_DURATION=$((BOOT_END_TIME - BOOT_START_TIME))
        log_msg "INFO" "Boot verification: Boot completed in ${BOOT_DURATION}s"
    fi
) &

# v1.2.0: Network-aware keybox update check (moved from post-fs-data)
# Only runs after network is confirmed available
if [ -f "$MODPATH/keybox_updater.sh" ]; then
    (
        log_msg "INFO" "Waiting for network before keybox check..."
        NETWORK_WAIT=0
        while [ "$NETWORK_WAIT" -lt 60 ]; do
            # Check network availability (ping or check default route)
            if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
                log_msg "INFO" "Network available - running keybox update check"
                break
            fi
            # Also check if we have a default route
            if ip route 2>/dev/null | grep -q default; then
                sleep 5
                NETWORK_WAIT=$((NETWORK_WAIT + 5))
            else
                sleep 5
                NETWORK_WAIT=$((NETWORK_WAIT + 5))
            fi
        done
        
        if [ "$NETWORK_WAIT" -lt 60 ]; then
            sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1
            log_msg "INFO" "Keybox update check completed"
        else
            log_msg "WARN" "Network not available after 60s - skipping keybox update check"
        fi
    ) &
    KEYBOX_PID=$!
    log_msg "INFO" "Keybox checker started (PID: $KEYBOX_PID)"
fi

# Wait for boot completion, then start monitor in background
wait_for_boot

log_msg "INFO" "Starting target app monitor"

# v1.2.0: Verify boot health after wait_for_boot
if is_boot_completed; then
    log_msg "INFO" "Boot verification: Boot sequence completed normally"
    verify_boot
else
    log_msg "WARN" "Boot verification: Boot wait timed out - monitor starting with reduced activity"
fi

# Use a POSIX-friendly detached subshell instead of 'disown'
(
    nohup sh -c '
        MODPATH="'"$MODPATH"'"
        . "$MODPATH/common_func.sh"
        
        # v1.1.0: Load addon functions if available
        if [ -f "$MODPATH/update_service_addon.sh" ]; then
            . "$MODPATH/update_service_addon.sh"
        fi
        
        # Wrapper to call keybox periodic check from monitor
        _monitor_target_apps() {
            last_state=""
            sleep_interval=10
            keybox_setup_done=false
            cycle_count=0
            
            while true; do
                if ! is_boot_completed; then
                    sleep 5
                    continue
                fi
                
                # Setup keybox environment once after boot
                if [ "$keybox_setup_done" = false ]; then
                    setup_keybox_environment 1
                    keybox_setup_done=true
                fi
                
                current_state=""
                found_any=false
                found_attestation_app=false
                
                while IFS= read -r pkg || [ -n "$pkg" ]; do
                    case "$pkg" in
                        ""|\#*) continue ;;
                    esac
                    if is_app_running "$pkg"; then
                        current_state="${current_state}${pkg};"
                        found_any=true
                        
                        # Check if this is an attestation-using app
                        if is_attestation_app "$pkg"; then
                            found_attestation_app=true
                        fi
                    fi
                done < "$MODPATH/target_apps.txt"
                
                # Adaptive sleep
                if [ "$found_any" = true ]; then
                    sleep_interval=3
                else
                    sleep_interval=10
                fi
                
                if [ "$current_state" != "$last_state" ]; then
                    if [ -n "$current_state" ]; then
                        log_msg "INFO" "Target apps detected: $current_state"
                        spoof_bootloader_locked
                        hide_build_properties
                        hide_magisk_traces
                        
                        # Apply keybox hiding for attestation apps
                        if [ "$found_attestation_app" = true ]; then
                            log_msg "INFO" "Attestation app detected - applying keybox spoofing"
                            spoof_keybox_properties
                            hide_keystore_traces
                        fi
                    fi
                    last_state="$current_state"
                fi
                
                # v1.1.0: Periodic keybox update check (every ~10 hours)
                cycle_count=$((cycle_count + 1))
                if [ "$cycle_count" -ge 3600 ]; then
                    cycle_count=0
                    if [ -f "$MODPATH/keybox_updater.sh" ]; then
                        sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1 &
                    fi
                fi
                
                # v1.2.0: Periodic boot verification in monitor
                if [ "$cycle_count" -eq 1800 ]; then
                    # Every ~5 hours, verify boot marker is still good
                    if [ -f "$MODPATH/.post_fs_data_done" ]; then
                        PFS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
                        if [ "$PFS" = "1" ]; then
                            log_msg "INFO" "Boot verification: post-fs-data still marked complete"
                        fi
                    fi
                fi
                
                sleep "$sleep_interval"
            done
        }
        
        _monitor_target_apps
    ' >/dev/null 2>&1 &
)

log_msg "INFO" "Service spawn complete, monitor detached"
exit 0
