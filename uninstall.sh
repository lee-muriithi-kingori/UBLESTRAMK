#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Uninstall Script
# Clean removal of all module files
#
# CHANGES (v1.1.0):
# - Added cleanup for webui configuration files
# - Added cleanup for keybox updater files
# ==========================================

MODPATH="${0%/*}"
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"

log_msg() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] UBLESTRAMK: $msg" >> "$LOG_FILE" 2>/dev/null
}

log_msg "INFO" "Starting UBLESTRAMK uninstallation"

# Clean up configuration files (v1.1.0)
for config_file in \
    "$MODPATH/.keybox_source_type" \
    "$MODPATH/.keybox_source_url" \
    "$MODPATH/.keybox_auto_update" \
    "$MODPATH/.keybox_update_interval" \
    "$MODPATH/.keybox_last_update" \
    "$MODPATH/.keybox_check_counter" \
    "$MODPATH/.keybox_ready" \
    "$MODPATH/.keybox_security_level" \
    "$MODPATH/.attestation_mode" \
    "$MODPATH/.spoof_bootloader" \
    "$MODPATH/.spoof_properties" \
    "$MODPATH/.hide_keystore"; do
    if [ -f "$config_file" ]; then
        rm -f "$config_file"
    fi
done

# Clean up keybox backups
for backup in "$MODPATH"/keybox.xml.bak.*; do
    [ -f "$backup" ] && rm -f "$backup"
done

# Note: The module directory itself will be removed by the root manager
log_msg "INFO" "UBLESTRAMK uninstalled cleanly"
