#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Customize Script (Installation)
# Runs during module installation
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
ui_print "  Version: v0.9.0-beta"
ui_print "  Author: lee-muriithi-kingori"
ui_print "  Status: BETA - Community Testing Phase"
ui_print "============================================"
ui_print ""

# Detect root solution
if [ -n "${KSU}" ] && [ "${KSU}" = "true" ]; then
    ui_print "- KernelSU detected"
    ui_print "- Make sure 'Unmount modules' is enabled"
    ui_print "  for target apps in KernelSU Manager"
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
ui_print "- Installing UBLESTRAMK..."

# Set permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/common_func.sh" 0 0 0644
set_perm "$MODPATH/target_apps.txt" 0 0 0644
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/hide_root.sh" 0 0 0755

# Create log file
touch /data/local/tmp/UBLESTRAMK.log
chmod 644 /data/local/tmp/UBLESTRAMK.log

ui_print "- Installation complete"
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
ui_print "3. Clear app data for target apps"
ui_print "   after first boot with module"
ui_print ""
ui_print "4. Target apps are configured in:"
ui_print "   /data/adb/modules/UBLESTRAMK/"
ui_print "   target_apps.txt"
ui_print ""
ui_print "5. For issues, visit:"
ui_print "   github.com/lee-muriithi-kingori/"
ui_print "   UBLESTRAMK/issues"
ui_print ""
ui_print "============================================"
ui_print "  BETA NOTICE:"
ui_print "  This is a beta release. Please report"
ui_print "  any issues for community improvement."
ui_print "  Devs shouldn't pay for fear."
ui_print "============================================"
