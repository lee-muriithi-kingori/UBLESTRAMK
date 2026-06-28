#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Action Script
# Runs when user clicks the action button
# in Magisk/KernelSU Manager
#
# CHANGES (audit-fixes):
# - Replaced log wipe with log rotation (security fix)
#   Wiping logs destroys the audit trail of what the module did.
#   Rotating preserves the last 5 runs for debugging while keeping
#   the log file from growing unbounded.
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

# Action: Force re-apply hiding + rotate logs
log_msg "INFO" "Action button triggered - re-applying all hiding"

# Re-apply all spoofing
spoof_bootloader_locked
hide_build_properties

# Rotate logs instead of wiping them. Keep up to 5 backups.
# This preserves diagnostic history for debugging while preventing
# the log from growing indefinitely.
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"
if [ -f "$LOG_FILE" ]; then
    # Remove oldest backup
    rm -f "${LOG_FILE}.5" 2>/dev/null
    # Shift backups
    for i in 4 3 2 1; do
        if [ -f "${LOG_FILE}.${i}" ]; then
            mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i + 1))" 2>/dev/null || true
        fi
    done
    # Move current to .1
    mv "$LOG_FILE" "${LOG_FILE}.1" 2>/dev/null || true
fi

# Start fresh log
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log_msg "INFO" "All hiding re-applied via action button (log rotated)"

# Note: post-boot toast notifications from a shell script are unreliable
# across Android versions (service call API varies by SDK). The action
# button is meant for the Magisk/KernelSU Manager UI; logs are sufficient.
