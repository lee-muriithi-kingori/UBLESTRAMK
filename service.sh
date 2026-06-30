#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Script (Late Start)
# Main hiding logic - runs after boot completes
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

log_msg "INFO" "=== UBLESTRAMK service starting ==="
log_msg "INFO" "Version: $(get_version)"

# v1.1.0: Initialize webui configuration
if [ -f "$MODPATH/update_service_addon.sh" ]; then
    . "$MODPATH/update_service_addon.sh"
    ensure_webui_config
    log_msg "INFO" "WebUI configuration initialized"
fi

# v1.1.0: Run initial keybox update check if needed
if [ -f "$MODPATH/keybox_updater.sh" ]; then
    log_msg "INFO" "Running initial keybox check..."
    sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1 &
fi

# Apply initial bootloader spoof on boot
spoof_bootloader_locked
hide_build_properties

# Background worker: late-boot properties
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
) &

# Wait for boot completion, then start monitor in background
wait_for_boot

log_msg "INFO" "Starting target app monitor"

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
            local last_state=""
            local sleep_interval=10
            local keybox_setup_done=false
            local cycle_count=0
            
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
                
                local current_state=""
                local found_any=false
                local found_attestation_app=false
                
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
                
                sleep "$sleep_interval"
            done
        }
        
        _monitor_target_apps
    ' >/dev/null 2>&1 &
)

log_msg "INFO" "Service spawn complete, monitor detached"
exit 0
