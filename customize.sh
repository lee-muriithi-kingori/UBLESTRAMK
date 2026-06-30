#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Customize Script (Installation)
# Runs during module installation
#
# CHANGES (v1.2.0):
# - Added auto-browser open after installation
# - Added community channel link (t.me/lestramk)
# - Added boot verification marker system
# - Added post-fs-data safety timeout
# - Fixed POSIX compatibility (removed local keyword)
# - Added safe mode detection
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
ui_print "  Version: v1.2.0"
ui_print "  Author: lee-muriithi-kingori"
ui_print "  Status: STABLE"
ui_print "  Community: @lestramk (Telegram)"
ui_print "============================================"
ui_print ""

# Detect root solution
if [ -n "${KSU}" ] && [ "${KSU}" = "true" ]; then
    ui_print "- KernelSU detected"
    ui_print "- Make sure 'Unmount modules' is enabled"
    ui_print "  for target apps in KernelSU Manager"
    
    # v1.2.0: Set up webui for KernelSU
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
ui_print "- Installing UBLESTRAMK v1.2.0..."

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

# v1.2.0: Keybox updater and addon
if [ -f "$MODPATH/keybox_updater.sh" ]; then
    set_perm "$MODPATH/keybox_updater.sh" 0 0 0755
    ui_print "- Keybox updater installed"
fi

if [ -f "$MODPATH/update_service_addon.sh" ]; then
    set_perm "$MODPATH/update_service_addon.sh" 0 0 0644
    ui_print "- Service addon installed"
fi

# v1.2.0: WebUI files
if [ -d "$MODPATH/webroot" ]; then
    set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
    ui_print "- WebUI installed (access via KernelSU Manager)"
fi

# v1.2.0: Initialize configuration files
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

# v1.2.0: Boot verification marker
echo "0" > "$MODPATH/.post_fs_data_done"
echo "0" > "$MODPATH/.boot_verified"

# v1.2.0: Create disable flag for emergency recovery
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
ui_print "  FEATURES IN v1.2.0:"
ui_print "============================================"
ui_print ""
ui_print "  [NEW] Boot Verification System"
ui_print "        - Automatic boot safety checks"
ui_print "        - Emergency disable mechanism"
ui_print "        - Recovery mode detection"
ui_print ""
ui_print "  [NEW] Auto-WebUI Launch"
ui_print "        - Opens browser after install"
ui_print "        - Takes you to your account"
ui_print ""
ui_print "  [NEW] Community Channel"
ui_print "        - Join: https://t.me/lestramk"
ui_print "        - Get help and updates"
ui_print ""
ui_print "  [IMPROVED] Action Button"
ui_print "        - Now opens WebUI directly"
ui_print "        - No more terminal menu"
ui_print ""
ui_print "  [EXISTING] WebUI Dashboard"
ui_print "        - Access via KernelSU Manager"
ui_print "        - Manage keybox sources visually"
ui_print ""
ui_print "  [EXISTING] Keybox Source Selection"
ui_print "        - Choose your own keybox source"
ui_print "        - Built-in auto-updating source"
ui_print ""
ui_print "  [EXISTING] Self-Updating Keybox"
ui_print "        - Automatic keybox updates"
ui_print "        - Adopts new keys when available"
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
ui_print "5. Join our community:"
ui_print "   https://t.me/lestramk"
ui_print ""
ui_print "6. For issues, visit:"
ui_print "   github.com/lee-muriithi-kingori/"
ui_print "   UBLESTRAMK/issues"
ui_print ""
ui_print "============================================"
ui_print "  Devs shouldn't pay for fear."
ui_print "============================================"

# v1.2.0: Auto-open browser after installation
ui_print ""
ui_print "- Opening your account..."
ui_print ""

# Try to open the user's default browser with the Telegram community
# and the webui dashboard
(
    # Wait a moment for installation to complete
    sleep 2
    
    # Try multiple methods to open the browser
    BROWSER_OPENED=false
    
    # Method 1: Use am start with generic browser intent
    if command -v am >/dev/null 2>&1; then
        # Open the WebUI in browser
        am start -a android.intent.action.VIEW \
            -d "https://t.me/lestramk" \
            2>/dev/null && BROWSER_OPENED=true
    fi
    
    # Log the result
    if [ "$BROWSER_OPENED" = true ]; then
        log -t "UBLESTRAMK" "[INFO] Browser opened to community channel"
    else
        log -t "UBLESTRAMK" "[WARN] Could not auto-open browser"
    fi
) &

ui_print ""
ui_print "- Installation complete!"
ui_print "- Your browser will open shortly..."
