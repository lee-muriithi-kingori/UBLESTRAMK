#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Uninstall Script
# Runs when module is removed
# ==========================================

MODPATH="${0%/*}"
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] UBLESTRAMK uninstalling..." >> "$LOG_FILE" 2>/dev/null
log -t "UBLESTRAMK" "Module uninstalling" 2>/dev/null || true

# Clean up log file on uninstall
if [ -f "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
fi

# Note: Properties will automatically revert after reboot
# since they were set via resetprop (volatile)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] UBLESTRAMK uninstalled. Reboot to complete removal." >> "$LOG_FILE" 2>/dev/null
