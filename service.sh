#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Script (Late Start)
# Main hiding logic - runs after boot completes
# Version: v1.3.0
#
# CHANGES (v1.3.0):
# - Updated version to v1.3.0
# - Improved WebUI service initialization
# - Added passmark-aware status reporting
#
# CHANGES (v1.2.0):
# - ADDED boot verification system
# - ADDED boot failure tracking and recovery
# - ADDED safe mode detection and reduced activity mode
# - ADDED network-aware keybox update
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

BOOT_START_TIME=$(date +%s 2>/dev/null || echo 0)

log_msg "INFO" "=== UBLESTRAMK service starting ==="
log_msg "INFO" "$(get_module_info_line)"
log_msg "INFO" "Community: $LESTRAMK_COMMUNITY"
log_msg "INFO" "Issues: $LESTRAMK_REPO/issues"

# Boot verification - check if post-fs-data completed
if [ -f "$MODPATH/.post_fs_data_done" ]; then
    PFS_STATUS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
    if [ "$PFS_STATUS" = "1" ]; then
        log_msg "INFO" "Boot verification: post-fs-data completed"
    else
        log_msg "WARN" "Boot verification: post-fs-data incomplete"
    fi
else
    log_msg "WARN" "Boot verification: post-fs-data marker missing"
    echo "0" > "$MODPATH/.post_fs_data_done" 2>/dev/null || true
fi

# Check for safe mode
if [ -f "$MODPATH/.safe_mode_detected" ]; then
    log_msg "INFO" "Safe mode detected - running minimal service"
    sleep 30
    echo "0" > "$MODPATH/.boot_verified" 2>/dev/null || true
    exit 0
fi

# Initialize webui configuration
if [ -f "$MODPATH/update_service_addon.sh" ]; then
    . "$MODPATH/update_service_addon.sh"
    ensure_webui_config
    log_msg "INFO" "WebUI initialized"
    log_msg "INFO" "Access: Tap UBLESTRAMK module card"
fi

# Apply initial bootloader spoof on boot
spoof_bootloader_locked
hide_build_properties

# Background worker - late-boot properties
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
    
    log_msg "INFO" "Late-boot properties applied"
    
    if is_boot_completed; then
        echo "1" > "$MODPATH/.boot_verified" 2>/dev/null || true
        BOOT_END_TIME=$(date +%s 2>/dev/null || echo 0)
        BOOT_DURATION=$((BOOT_END_TIME - BOOT_START_TIME))
        log_msg "INFO" "Boot completed in ${BOOT_DURATION}s"
    fi
) &

# Network-aware keybox update check
if [ -f "$MODPATH/keybox_updater.sh" ]; then
    (
        log_msg "INFO" "Waiting for network..."
        NETWORK_WAIT=0
        while [ "$NETWORK_WAIT" -lt 60 ]; do
            if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
                log_msg "INFO" "Network available - keybox check"
                break
            fi
            sleep 5
            NETWORK_WAIT=$((NETWORK_WAIT + 5))
        done
        
        if [ "$NETWORK_WAIT" -lt 60 ]; then
            sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1
            log_msg "INFO" "Keybox update check done"
        else
            log_msg "WARN" "Network timeout - skipping keybox check"
        fi
    ) &
    KEYBOX_PID=$!
    log_msg "INFO" "Keybox checker PID: $KEYBOX_PID"
fi

# Wait for boot, start monitor
wait_for_boot
log_msg "INFO" "Starting target app monitor"

if is_boot_completed; then
    log_msg "INFO" "Boot sequence completed normally"
    verify_boot
else
    log_msg "WARN" "Boot wait timeout - monitor starting reduced"
fi

# Detached monitor subshell
(
    nohup sh -c '
        MODPATH="'"$MODPATH"'"
        . "$MODPATH/common_func.sh"
        
        if [ -f "$MODPATH/update_service_addon.sh" ]; then
            . "$MODPATH/update_service_addon.sh"
        fi
        
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
                        
                        if is_attestation_app "$pkg"; then
                            found_attestation_app=true
                        fi
                    fi
                done < "$MODPATH/target_apps.txt"
                
                if [ "$found_any" = true ]; then
                    sleep_interval=3
                else
                    sleep_interval=10
                fi
                
                if [ "$current_state" != "$last_state" ]; then
                    if [ -n "$current_state" ]; then
                        log_msg "INFO" "Target apps: $current_state"
                        spoof_bootloader_locked
                        hide_build_properties
                        hide_magisk_traces
                        
                        if [ "$found_attestation_app" = true ]; then
                            log_msg "INFO" "Attestation app - keybox spoofing"
                            spoof_keybox_properties
                            hide_keystore_traces
                        fi
                    fi
                    last_state="$current_state"
                fi
                
                cycle_count=$((cycle_count + 1))
                if [ "$cycle_count" -ge 3600 ]; then
                    cycle_count=0
                    if [ -f "$MODPATH/keybox_updater.sh" ]; then
                        sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1 &
                    fi
                fi
                
                if [ "$cycle_count" -eq 1800 ]; then
                    if [ -f "$MODPATH/.post_fs_data_done" ]; then
                        PFS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
                        if [ "$PFS" = "1" ]; then
                            log_msg "INFO" "Boot verification: OK"
                        fi
                    fi
                fi
                
                sleep "$sleep_interval"
            done
        }
        
        _monitor_target_apps
    ' >/dev/null 2>&1 &
)

log_msg "INFO" "Service spawn complete"
exit 0
