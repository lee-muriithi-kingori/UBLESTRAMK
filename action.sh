#!/system/bin/sh
# UBLESTRAMK Action Script v1.4.0
MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

echo "================================"
echo "  UBLESTRAMK <v1.4.0>"
echo "  Passmark: 99.9%"
echo "  Root: $(detect_root_solution)"
echo "================================"
echo ""

if [ -f "$MODPATH/.post_fs_data_done" ]; then
    PFS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
    [ "$PFS" = "1" ] && echo "[OK] Module initialized" || echo "[!] Init incomplete - reboot recommended"
else
    echo "[!] First boot - reboot required"
fi

if [ -f "$MODPATH/keybox.xml" ]; then
    KB_HAS_PH=$(grep -c "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
    if [ "$KB_HAS_PH" -gt 0 ]; then echo "[!] Keybox has placeholders"
    else echo "[OK] Keybox active"; fi
else echo "[!] No keybox.xml"; fi

echo ""
echo "Current Settings:"
for cfg in spoof_bootloader spoof_properties hide_keystore; do
    val=$(read_config_safe "$cfg" "1")
    status=$([ "$val" = "1" ] && echo "ON" || echo "OFF")
    echo "  $cfg: $status"
done
echo ""
echo "Opening WebUI..."
echo ""

WEBUI_PATH=""
for path in "/data/adb/modules_update/UBLESTRAMK/webroot/index.html" \
            "$MODPATH/webroot/index.html" \
            "/data/adb/modules/UBLESTRAMK/webroot/index.html"; do
    [ -f "$path" ] && { WEBUI_PATH="$path"; break; }
done

if [ -z "$WEBUI_PATH" ]; then echo "[ERROR] WebUI not found"; exit 1; fi

WEBUI_URL="file://${WEBUI_PATH}"
HAS_OPENED=false

if is_kernelsu && command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "$WEBUI_URL" \
        -n me.weishu.kernelsu/.ui.webui.WebUIActivity 2>/dev/null && HAS_OPENED=true
fi

if [ "$HAS_OPENED" = false ] && is_apatch && command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "$WEBUI_URL" \
        -n me.bmax.apatch/.ui.webui.WebUIActivity 2>/dev/null && HAS_OPENED=true
fi

if [ "$HAS_OPENED" = false ] && command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "$WEBUI_URL" 2>/dev/null && HAS_OPENED=true
fi

if [ "$HAS_OPENED" = true ]; then
    echo "[OK] WebUI opened"
else
    echo "[!] Could not open WebUI"
    echo ""
    echo "Manual access:"
    echo "  KernelSU: Tap UBLESTRAMK card"
    echo "  APatch: Tap UBLESTRAMK card"
    echo "  Magisk: Tap action button"
    echo "  Browser: $WEBUI_URL"
    echo "  Telegram: https://t.me/lestramk"
fi
exit 0
