#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Script (Late Start)
# Main hiding logic - runs after boot completes
# Monitors for target apps and applies evasion
#
# IMPORTANT: Magisk's service.sh is expected to fork background work
# and exit quickly. Blocking here breaks Magisk's service lifecycle
# and can cause bootloops. We follow the spawn-and-exit pattern.
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

log_msg "INFO" "=== UBLESTRAMK service starting ==="
log_msg "INFO" "Version: $(get_version)"

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
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    log_msg "INFO" "Late-boot properties applied"
) &

# Wait for boot completion, then start monitor in background
wait_for_boot

log_msg "INFO" "Starting target app monitor"
monitor_target_apps &
MONITOR_PID=$!

# Detach from the parent shell so Magisk doesn't block on us
disown $MONITOR_PID 2>/dev/null || true

log_msg "INFO" "Service spawn complete, monitor detached"
exit 0