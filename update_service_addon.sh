#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Service Addon Script
# Additional service functions for v1.1.0
# Handles keybox auto-updates and webui
# ==========================================

MODPATH="${MODPATH:-/data/adb/modules/UBLESTRAMK}"

# Keybox periodic update checker (runs in monitor loop)
keybox_periodic_check() {
    local check_counter_file="$MODPATH/.keybox_check_counter"
    local check_interval=60  # Check every 60 monitor cycles (~10 min each = every 10 hours)
    
    # Read counter
    local counter=0
    if [ -f "$check_counter_file" ]; then
        counter=$(cat "$check_counter_file" 2>/dev/null || echo 0)
    fi
    
    counter=$((counter + 1))
    
    if [ "$counter" -ge "$check_interval" ]; then
        # Time to check for updates
        if [ -f "$MODPATH/keybox_updater.sh" ]; then
            sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1 &
        fi
        counter=0
    fi
    
    # Save counter
    echo "$counter" > "$check_counter_file"
}

# WebUI configuration check
ensure_webui_config() {
    # Ensure keybox source type is set
    if [ ! -f "$MODPATH/.keybox_source_type" ]; then
        echo "default" > "$MODPATH/.keybox_source_type"
    fi
    
    # Ensure auto-update is set
    if [ ! -f "$MODPATH/.keybox_auto_update" ]; then
        echo "1" > "$MODPATH/.keybox_auto_update"
    fi
    
    # Ensure update interval is set
    if [ ! -f "$MODPATH/.keybox_update_interval" ]; then
        echo "24" > "$MODPATH/.keybox_update_interval"
    fi
    
    # Ensure attestation mode is set
    if [ ! -f "$MODPATH/.attestation_mode" ]; then
        echo "spoof" > "$MODPATH/.attestation_mode"
    fi
    
    # Ensure security level is set
    if [ ! -f "$MODPATH/.keybox_security_level" ]; then
        echo "tee" > "$MODPATH/.keybox_security_level"
    fi
    
    # Ensure spoof settings are set
    if [ ! -f "$MODPATH/.spoof_bootloader" ]; then
        echo "1" > "$MODPATH/.spoof_bootloader"
    fi
    if [ ! -f "$MODPATH/.spoof_properties" ]; then
        echo "1" > "$MODPATH/.spoof_properties"
    fi
    if [ ! -f "$MODPATH/.hide_keystore" ]; then
        echo "1" > "$MODPATH/.hide_keystore"
    fi
}
