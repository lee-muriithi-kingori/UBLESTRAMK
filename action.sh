#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Action Script
# Runs when user clicks the action button
# in Magisk/KernelSU Manager
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

# Action: Force re-apply hiding + clear logs
log_msg "INFO" "Action button triggered - re-applying all hiding"

# Re-apply all spoofing
spoof_bootloader_locked
hide_build_properties

# Clear and restart log
rm -f /data/local/tmp/UBLESTRAMK.log
touch /data/local/tmp/UBLESTRAMK.log
chmod 644 /data/local/tmp/UBLESTRAMK.log

log_msg "INFO" "All hiding re-applied via action button"

# Show a brief toast if possible
if command -v service >/dev/null 2>&1; then
    service call notification 1 s16 "UBLESTRAMK" s16 "Hiding reapplied successfully" i32 1 i32 0 2>/dev/null || true
fi
