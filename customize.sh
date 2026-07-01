#!/system/bin/sh
# UBLESTRAMK Customize Script v1.4.1

[ "$(id -u)" != "0" ] && { ui_print "! Must be root"; abort "Not root"; }

ui_print "============================================"
ui_print "  UBLESTRAMK <v1.4.1>"
ui_print "  Universal Boot-Lock Evasion"
ui_print "        & Stealth Root Admin Module"
ui_print "============================================"
ui_print "  Author: lee-muriithi-kingori"
ui_print "  Passmark: 99.9%"
ui_print "  Community: @lestramk"
ui_print "============================================"
ui_print ""

if [ -n "${KSU}" ] && [ "${KSU}" = "true" ]; then
    ui_print "- KernelSU detected"
    ui_print "- Enable 'Unmount modules' for targets"
    [ -d "$MODPATH/webroot" ] && ui_print "- WebUI: Tap module card"
elif [ -n "${APATCH}" ] && [ "${APATCH}" = "true" ]; then
    ui_print "- APatch detected"
    ui_print "- Enable 'Unmount modules' for targets"
    [ -d "$MODPATH/webroot" ] && ui_print "- WebUI: Tap module card"
elif [ -n "${MAGISK_VER_CODE}" ]; then
    ui_print "- Magisk v${MAGISK_VER} detected"
    [ "${MAGISK_VER_CODE}" -lt 27000 ] && { ui_print "! WARNING: Old Magisk"; ui_print "! Recommend 27.0+"; }
    ui_print "- Add targets to DenyList"
    ui_print "- Turn OFF 'Enforce DenyList'"
    ui_print "- Action button opens WebUI"
else
    ui_print "- Unknown root solution"
fi

ui_print ""
ui_print "- Installing UBLESTRAMK <v1.4.1>..."

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/common_func.sh" 0 0 0644
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/target_apps.txt" 0 0 0644
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/hide_root.sh" 0 0 0755

[ -f "$MODPATH/keybox_updater.sh" ] && { set_perm "$MODPATH/keybox_updater.sh" 0 0 0755; ui_print "- Keybox updater installed"; }
[ -f "$MODPATH/update_service_addon.sh" ] && { set_perm "$MODPATH/update_service_addon.sh" 0 0 0644; ui_print "- Service addon installed"; }
[ -d "$MODPATH/webroot" ] && { set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644; ui_print "- WebUI dashboard installed"; }
[ -d "$MODPATH/zygisk" ] && { set_perm_recursive "$MODPATH/zygisk" 0 0 0755 0644; ui_print "- Zygisk native module installed"; }

ui_print "- Initializing configuration..."

init_config() {
    key="$1"; value="$2"; file="$MODPATH/.${key}"
    echo "$value" > "$file" && chmod 644 "$file"
    read_back=$(cat "$file" 2>/dev/null)
    [ "$read_back" = "$value" ] && return 0
    ui_print "! WARNING: Config $key may not persist"
    return 1
}

init_config "keybox_source_type" "default"
init_config "keybox_auto_update" "1"
init_config "keybox_update_interval" "24"
init_config "attestation_mode" "spoof"
init_config "keybox_security_level" "tee"
init_config "spoof_bootloader" "1"
init_config "spoof_properties" "1"
init_config "hide_keystore" "1"
init_config "keybox_source_url" ""
init_config "post_fs_data_done" "0"
init_config "boot_verified" "0"
init_config "boot_failed" "0"

touch "$MODPATH/disable" 2>/dev/null
rm -f "$MODPATH/disable" 2>/dev/null

touch /data/local/tmp/UBLESTRAMK.log
chmod 644 /data/local/tmp/UBLESTRAMK.log

echo "1" > "$MODPATH/.install_complete"
chmod 644 "$MODPATH/.install_complete"

ui_print ""
ui_print "============================================"
ui_print "  UBLESTRAMK <v1.4.1> FEATURES:"
ui_print "============================================"
ui_print ""
ui_print "  [WEBUI] Full Settings Persistence"
ui_print "          - Toggle features real-time"
ui_print "          - Settings survive reboots"
ui_print "          - KernelSU/APatch: Tap card"
ui_print "          - Magisk: Tap action button"
ui_print ""
ui_print "  [99.9%] Passmark Score"
ui_print "  [KEYBOX] Self-Updating Keybox"
ui_print "  [ZYGISK] Native C++ Root Hiding"
ui_print "  [HIDE]   Stealth Root Admin"
ui_print ""
ui_print "============================================"
ui_print "  SETUP:"
ui_print "    1. REBOOT now"
ui_print "    2. Add apps to DenyList/Unmount"
ui_print "    3. Open WebUI Dashboard"
ui_print "    4. Clear target app data"
ui_print "    5. Community: @lestramk"
ui_print "============================================"

( sleep 2; command -v am >/dev/null 2>&1 && \
  am start -a android.intent.action.VIEW -d "https://t.me/lestramk" 2>/dev/null ) &

ui_print ""
ui_print "- Installation complete!"
