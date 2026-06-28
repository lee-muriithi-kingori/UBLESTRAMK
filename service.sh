#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Script (Late Start)
# Main hiding logic - runs after boot completes
# Monitors for target apps and applies evasion
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

log_msg "INFO" "=== UBLESTRAMK service starting ==="
log_msg "INFO" "Version: $(get_version)"

# Wait for boot to complete before starting monitoring
wait_for_boot

# Apply initial bootloader spoof on boot
spoof_bootloader_locked
hide_build_properties

# Additional late-boot properties
{
    # Wait a bit more for stability
    sleep 10
    
    # Bootloader lock state (must be set after boot_completed for various OEMs)
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    
    # OEM unlock prevention
    resetprop_if_diff sys.oem_unlock_allowed 0
    
    # Delete SELinux build indicator
    if [ "$SKIPDELPROP" = false ]; then
        delprop_if_exist ro.build.selinux
    fi
    
    # OnePlus/Oppo specific for OOS/ColorOS 12+
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    
    log_msg "INFO" "Late-boot properties applied"
}&

# Continuous monitoring loop
log_msg "INFO" "Starting target app monitor"
monitor_target_apps &
MONITOR_PID=$!

# Handle module disable/remove signals
trap 'kill $MONITOR_PID 2>/dev/null; log_msg "INFO" "Service stopping"; exit 0' TERM INT

# Keep service alive
wait $MONITOR_PID

log_msg "WARN" "Monitor process exited unexpectedly, restarting..."

# Restart monitor if it crashes
sleep 5
exec "$MODPATH/service.sh"
