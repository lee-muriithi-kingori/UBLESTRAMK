#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Customize Script (Installation)
# Runs during module installation
#
# CHANGES (v1.1.0):
# - Added webui files installation
# - Added keybox_updater.sh setup
# - Added configuration file initialization
# - Added permission settings for new files
# ==========================================

# Abort if not running as root
if [ "$(id -u)" != "0" ]; then
    ui_print "! ERROR: Must be installed as root"
    abort "Installation failed - not root"
fi

# Show banner
ui_print "============================================"
ui_print "  UBLESTRAMK - Universal Boot-Lock Evasion"
ui_print "        & Stealth Root Admin Module"
ui_print "============================================"
ui_print "  Version: v1.1.0"
ui_print "  Author: lee-muriithi-kingori"
ui_print "  Status: STABLE"
ui_print "============================================"
ui_print ""

# Detect root solution
if [ -n "${KSU}" ] && [ "${KSU}" = "true" ]; then
    ui_print "- KernelSU detected"
    ui_print "- Make sure 'Unmount modules' is enabled"
    ui_print "  for target apps in KernelSU Manager"
    
    # v1.1.0: Set up webui for KernelSU
    if [ -d "$MODPATH/webroot" ]; then
        ui_print "- WebUI available in KernelSU Manager"
    fi
    
elif [ -n "${APATCH}" ] && [ "${APATCH}" = "true" ]; then
    ui_print "- APatch detected"
    ui_print "- Make sure 'Unmount modules' is enabled"
    ui_print "  for target apps in APatch Manager"
    
elif [ -n "${MAGISK_VER_CODE}" ]; then
    ui_print "- Magisk v${MAGISK_VER} detected"
    if [ "${MAGISK_VER_CODE}" -lt 27000 ]; then
        ui_print "! WARNING: Magisk ${MAGISK_VER} detected"
        ui_print "! Recommend Magisk 27.0+ for best hiding"
    fi
    ui_print "- Add target apps to DenyList"
    ui_print "- Turn OFF 'Enforce DenyList'"
else
    ui_print "- Unknown root solution detected"
fi

ui_print ""
ui_print "- Installing UBLESTRAMK v1.1.0..."

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

# v1.1.0: Keybox updater and addon
if [ -f "$MODPATH/keybox_updater.sh" ]; then
    set_perm "$MODPATH/keybox_updater.sh" 0 0 0755
    ui_print "- Keybox updater installed"
fi

if [ -f "$MODPATH/update_service_addon.sh" ]; then
    set_perm "$MODPATH/update_service_addon.sh" 0 0 0644
    ui_print "- Service addon installed"
fi

# v1.1.0: WebUI files
if [ -d "$MODPATH/webroot" ]; then
    set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
    ui_print "- WebUI installed (access via KernelSU Manager)"
fi

# v1.1.0: Initialize configuration files
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

# Set permissions for config files
for config_file in \
    "$MODPATH/.keybox_source_type" \
    "$MODPATH/.keybox_auto_update" \
    "$MODPATH/.keybox_update_interval" \
    "$MODPATH/.attestation_mode" \
    "$MODPATH/.keybox_security_level" \
    "$MODPATH/.spoof_bootloader" \
    "$MODPATH/.spoof_properties" \
    "$MODPATH/.hide_keystore"; do
    [ -f "$config_file" ] && chmod 644 "$config_file"
done

# Create log file
touch /data/local/tmp/UBLESTRAMK.log
chmod 644 /data/local/tmp/UBLESTRAMK.log

ui_print ""
ui_print "============================================"
ui_print "  FEATURES IN v1.1.0:"
ui_print "============================================"
ui_print ""
ui_print "  [NEW] WebUI Dashboard"
ui_print "        - Access via KernelSU/Magisk Manager"
ui_print "        - Manage keybox sources visually"
ui_print "        - View logs and module status"
ui_print ""
ui_print "  [NEW] Keybox Source Selection"
ui_print "        - Choose your own keybox source"
ui_print "        - Built-in auto-updating source"
ui_print "        - Support for custom URLs"
ui_print ""
ui_print "  [NEW] Self-Updating Keybox"
ui_print "        - Automatic keybox updates"
ui_print "        - Adopts new keys when available"
ui_print "        - Configurable update interval"
ui_print ""
ui_print "============================================"
ui_print "  IMPORTANT SETUP INSTRUCTIONS:"
ui_print "============================================"
ui_print ""
ui_print "1. REBOOT your device now"
ui_print ""
ui_print "2. Add apps to hide list:"
ui_print "   - Magisk: Add to DenyList"
ui_print "   - KernelSU: Enable 'Unmount modules'"
ui_print "   - APatch: Enable 'Unmount modules'"
ui_print ""
ui_print "3. Open WebUI (KernelSU users):"
ui_print "   - Open KernelSU Manager"
ui_print "   - Go to Modules > UBLESTRAMK"
ui_print "   - Tap the module card to open WebUI"
ui_print ""
ui_print "4. Clear app data for target apps"
ui_print "   after first boot with module"
ui_print ""
ui_print "5. For issues, visit:"
ui_print "   github.com/lee-muriithi-kingori/"
ui_print "   UBLESTRAMK/issues"
ui_print ""
ui_print "============================================"
ui_print "  Devs shouldn't pay for fear."
ui_print "============================================"
