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

# Note: post-boot toast notifications from a shell script are unreliable
# across Android versions (service call API varies by SDK). The action
# button is meant for the Magisk/KernelSU Manager UI; logs are sufficient.
