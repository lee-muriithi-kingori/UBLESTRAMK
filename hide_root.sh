#!/system/bin/sh
# ==========================================
# UBLESTRAMK - On-Demand Root Hiding Script
# Can be run manually for immediate hiding
# Usage: sh /data/adb/modules/UBLESTRAMK/hide_root.sh
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

log_msg "INFO" "=== Manual root hiding triggered ==="

# Apply all hiding measures
spoof_bootloader_locked
hide_build_properties
hide_magisk_traces

# Additional aggressive hiding when manually triggered
log_msg "INFO" "Applying aggressive manual hiding"

# Hide additional traces
resetprop_if_diff ro.boot.mode unknown
resetprop_if_diff ro.bootmode unknown
resetprop_if_diff persist.sys.adb.notify 0

# Clear possible log traces
dmesg -c >/dev/null 2>&1 || true

# Re-check running target apps
# Note: 'local' is NOT POSIX sh compatible outside functions.
# All variables here are scoped to this script's subprocess anyway.
found_apps=""
while IFS= read -r pkg || [ -n "$pkg" ]; do
    case "$pkg" in
        ""|\#*) continue ;;
    esac
    if is_app_running "$pkg"; then
        found_apps="${found_apps}${pkg} "
    fi
done < "$MODPATH/target_apps.txt"

if [ -n "$found_apps" ]; then
    log_msg "INFO" "Active target apps: $found_apps"
    echo "UBLESTRAMK: Hiding active for: $found_apps"
else
    log_msg "INFO" "No target apps currently running"
    echo "UBLESTRAMK: No target apps running. Props spoofed anyway."
fi

log_msg "INFO" "=== Manual hiding complete ==="
echo "UBLESTRAMK: Root hiding applied. Check log at /data/local/tmp/UBLESTRAMK.log"
