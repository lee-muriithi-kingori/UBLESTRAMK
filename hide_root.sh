#!/system/bin/sh
# UBLESTRAMK On-Demand Root Hiding v1.4.1
MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

log_msg "INFO" "=== Manual root hiding v1.4.1 ==="

spoof_bootloader_locked
hide_build_properties
hide_magisk_traces
# FIX: also hide keystore traces on manual run
if is_feature_enabled "hide_keystore"; then
    hide_keystore_traces
fi

resetprop_if_diff ro.boot.mode boot
resetprop_if_diff ro.bootmode boot
resetprop_if_diff persist.sys.adb.notify 0
dmesg -c >/dev/null 2>&1 || true

found_apps=""
while IFS= read -r pkg || [ -n "$pkg" ]; do
    case "$pkg" in ""|\#*) continue ;; esac
    if is_app_running "$pkg"; then found_apps="${found_apps}${pkg} "; fi
done < "$MODPATH/target_apps.txt"

[ -n "$found_apps" ] && log_msg "INFO" "Active targets: $found_apps" || log_msg "INFO" "No targets running"

log_msg "INFO" "=== Manual hiding complete ==="
echo "UBLESTRAMK: Root hiding applied. Check log: /data/local/tmp/UBLESTRAMK.log"
