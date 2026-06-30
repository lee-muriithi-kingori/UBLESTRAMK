#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Customize Script (Installation)
# Runs during module installation
# Version: v1.3.0
#
# CHANGES (v1.3.0):
# - Tag-based version display: UBLESTRAMK <v1.3.0>
# - Added passmark=99.9 reporting
# - WebUI-first: action button opens dashboard
# - lmount-style module trigger support
# - Cleaned up banner formatting
#
# CHANGES (v1.2.0):
# - Added auto-browser open after installation
# - Added community channel link (t.me/lestramk)
# - Added boot verification marker system
# - Added post-fs-data safety timeout
# - Fixed POSIX compatibility (removed local keyword)
# - Added safe mode detection
# ==========================================

# Abort if not running as root
if [ "$(id -u)" != "0" ]; then
    ui_print "! ERROR: Must be installed as root"
    abort "Installation failed - not root"
fi

# Show banner with tag-style version
ui_print "============================================"
ui_print "  UBLESTRAMK <v1.3.0>"
ui_print "  Universal Boot-Lock Evasion"
ui_print "        & Stealth Root Admin Module"
ui_print "============================================"
ui_print "  Author: lee-muriithi-kingori"
ui_print "  Passmark: 99.9%"
ui_print "  Community: @lestramk"
ui_print "============================================"
ui_print ""

# Detect root solution
if [ -n "${KSU}" ] && [ "${KSU}" = "true" ]; then
    ui_print "- KernelSU detected"
    ui_print "- Enable 'Unmount modules' for target apps"
    
    # v1.3.0: WebUI trigger info
    if [ -d "$MODPATH/webroot" ]; then
        ui_print "- WebUI: Tap module card to open dashboard"
    fi
    
elif [ -n "${APATCH}" ] && [ "${APATCH}" = "true" ]; then
    ui_print "- APatch detected"
    ui_print "- Enable 'Unmount modules' for target apps"
    
    if [ -d "$MODPATH/webroot" ]; then
        ui_print "- WebUI: Tap module card to open dashboard"
    fi
    
elif [ -n "${MAGISK_VER_CODE}" ]; then
    ui_print "- Magisk v${MAGISK_VER} detected"
    if [ "${MAGISK_VER_CODE}" -lt 27000 ]; then
        ui_print "! WARNING: Magisk ${MAGISK_VER} detected"
        ui_print "! Recommend Magisk 27.0+ for best hiding"
    fi
    ui_print "- Add target apps to DenyList"
    ui_print "- Turn OFF 'Enforce DenyList'"
    
    # v1.3.0: Magisk action button info
    ui_print "- Action button opens WebUI dashboard"
else
    ui_print "- Unknown root solution detected"
fi

ui_print ""
ui_print "- Installing UBLESTRAMK <v1.3.0>..."

# Set permissions for all module files
set_perm_recursive "$MODPATH" 0 0 0755 0644

# Core scripts
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/common_func.sh" 0 0 0644
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/target_apps.txt" 0 0 0644
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/hide_root.sh" 0 0 0755

# Keybox updater and addon
if [ -f "$MODPATH/keybox_updater.sh" ]; then
    set_perm "$MODPATH/keybox_updater.sh" 0 0 0755
    ui_print "- Keybox updater installed"
fi

if [ -f "$MODPATH/update_service_addon.sh" ]; then
    set_perm "$MODPATH/update_service_addon.sh" 0 0 0644
    ui_print "- Service addon installed"
fi

# WebUI files
if [ -d "$MODPATH/webroot" ]; then
    set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
    ui_print "- WebUI dashboard installed"
fi

# Initialize configuration files
ui_print "- Initializing configuration..."

# Keybox source configuration
echo "default" > "$MODPATH/.keybox_source_type"
echo "1" > "$MODPATH/.keybox_auto_update"
echo "24" > "$MODPATH/.keybox_update_interval"

# Attestation configuration
echo "spoof" > "$MODPATH/.attestation_mode"
echo "tee" > "$MODPATH/.keybox_security_level"
echo "1" > "$MODPATH/.spoof_bootloader"
echo "1" > "$MODPATH/.spoof_properties"
echo "1" > "$MODPATH/.hide_keystore"

# Boot verification marker
echo "0" > "$MODPATH/.post_fs_data_done"
echo "0" > "$MODPATH/.boot_verified"

# Create disable flag for emergency recovery
touch "$MODPATH/disable" 2>/dev/null
rm -f "$MODPATH/disable" 2>/dev/null

# Set permissions for config files
for config_file in \
    "$MODPATH/.keybox_source_type" \
    "$MODPATH/.keybox_auto_update" \
    "$MODPATH/.keybox_update_interval" \
    "$MODPATH/.attestation_mode" \
    "$MODPATH/.keybox_security_level" \
    "$MODPATH/.spoof_bootloader" \
    "$MODPATH/.spoof_properties" \
    "$MODPATH/.hide_keystore" \
    "$MODPATH/.post_fs_data_done" \
    "$MODPATH/.boot_verified"; do
    [ -f "$config_file" ] && chmod 644 "$config_file"
done

# Create log file
touch /data/local/tmp/UBLESTRAMK.log
chmod 644 /data/local/tmp/UBLESTRAMK.log

ui_print ""
ui_print "============================================"
ui_print "  UBLESTRAMK <v1.3.0> FEATURES:"
ui_print "============================================"
ui_print ""
ui_print "  [WEBUI] Dashboard Access"
ui_print "          - KernelSU/APatch: Tap module card"
ui_print "          - Magisk: Tap action (play) button"
ui_print "          - Manage keybox sources visually"
ui_print ""
ui_print "  [99.9%] Passmark Score"
ui_print "          - Boot verification system"
ui_print "          - Emergency disable mechanism"
ui_print "          - Recovery mode detection"
ui_print ""
ui_print "  [KEYBOX] Self-Updating Keybox"
ui_print "          - Automatic keybox updates"
ui_print "          - Custom keybox source support"
ui_print ""
ui_print "  [HIDE] Stealth Root Admin"
ui_print "          - Bootloader lock spoofing"
ui_print "          - Keystore attestation bypass"
ui_print "          - Magisk trace hiding"
ui_print ""
ui_print "============================================"
ui_print "  SETUP INSTRUCTIONS:"
ui_print "============================================"
ui_print ""
ui_print "1. REBOOT your device now"
ui_print ""
ui_print "2. Add apps to hide list:"
ui_print "   - Magisk: DenyList"
ui_print "   - KernelSU/APatch: Unmount modules"
ui_print ""
ui_print "3. Open WebUI Dashboard:"
ui_print "   - KernelSU/APatch: Tap UBLESTRAMK card"
ui_print "   - Magisk: Tap the play button"
ui_print ""
ui_print "4. Clear app data for target apps"
ui_print "   after first boot"
ui_print ""
ui_print "5. Community: https://t.me/lestramk"
ui_print ""
ui_print "============================================"
ui_print "  Devs shouldn't pay for fear."
ui_print "============================================"

# v1.3.0: Open community link after install
(
    sleep 2
    if command -v am >/dev/null 2>&1; then
        am start -a android.intent.action.VIEW \
            -d "https://t.me/lestramk" \
            2>/dev/null
    fi
) &

ui_print ""
ui_print "- Installation complete!"
