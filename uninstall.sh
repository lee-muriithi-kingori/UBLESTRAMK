#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Uninstall Script
# Runs when module is removed
#
# CHANGES (audit-fixes):
# - Removed log-write-before-delete race condition
#   The old code wrote to $LOG_FILE then immediately deleted it,
#   making the write pointless. Now we use the kernel log (log -t)
#   which persists independently of our log file.
# ==========================================

MODPATH="${0%/*}"
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"

# Use Android's system logger instead of writing to the file we're
# about to delete. This ensures the uninstall message is actually
# visible in logcat regardless of the race.
log -t "UBLESTRAMK" "Module uninstalling" 2>/dev/null || true

# Clean up log file and all rotated backups on uninstall
rm -f "$LOG_FILE" "${LOG_FILE}.1" "${LOG_FILE}.2" "${LOG_FILE}.3" "${LOG_FILE}.4" "${LOG_FILE}.5" 2>/dev/null

# Note: Properties will automatically revert after reboot
# since they were set via resetprop (volatile)
