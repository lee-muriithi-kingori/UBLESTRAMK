#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Script (Late Start)
# Main hiding logic - runs after boot completes
# Monitors for target apps and applies evasion
#
# IMPORTANT: Magisk's service.sh is expected to fork background work
# and exit quickly. Blocking here breaks Magisk's service lifecycle
# and can cause bootloops. We follow the spawn-and-exit pattern.
#
# CHANGES (audit-fixes):
# - Removed duplicate property sets (vendor.boot.verifiedbootstate and
#   ro.boot.vbmeta.device_state were each set twice)
# - Replaced 'disown' bashism with POSIX-compatible nohup subshell
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
    log_msg "INFO" "Late-boot properties applied"
) &

# Wait for boot completion, then start monitor in background
wait_for_boot

log_msg "INFO" "Starting target app monitor"

# Use a POSIX-friendly detached subshell instead of 'disown'
# which is a bashism not available in Android's /system/bin/sh.
# nohup + redirection ensures the monitor survives service.sh exit.
(
    nohup sh -c '
        MODPATH="'"$MODPATH"'"
        . "$MODPATH/common_func.sh"
        monitor_target_apps
    ' >/dev/null 2>&1 &
)

log_msg "INFO" "Service spawn complete, monitor detached"
exit 0
