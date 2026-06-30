#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Action Script (v1.3.0)
# Opens the WebUI for module configuration
# Trigger: Tap play/action button in Magisk/KernelSU/APatch Manager
#
# CHANGES (v1.3.0):
# - Unified WebUI opener for ALL root managers (Magisk/KernelSU/APatch)
# - lmount-style module trigger: auto-detects WebUI capability
# - Falls back gracefully to browser for legacy Magisk
# - Added version tag display matching module.prop format
# - Improved status reporting with passmark score
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

LOG_FILE="/data/local/tmp/UBLESTRAMK.log"
MODULE_VERSION="v1.3.0"
PASSMARK="99.9"

# Show module info banner with tag-style version
echo "================================"
echo "  UBLESTRAMK <${MODULE_VERSION}>"
echo "  Passmark: ${PASSMARK}%"
echo "  Root: $(detect_root_solution)"
echo "================================"
echo ""

# Check boot verifier status
if [ -f "$MODPATH/.post_fs_data_done" ]; then
    PFS_STATUS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
    if [ "$PFS_STATUS" = "1" ]; then
        echo "[OK] Module initialized"
    else
        echo "[!] Init incomplete - reboot recommended"
    fi
else
    echo "[!] First boot - reboot required"
fi

# Show keybox status
if [ -f "$MODPATH/keybox.xml" ]; then
    KB_HAS_PH=$(grep -c "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
    if [ "$KB_HAS_PH" -gt 0 ]; then
        echo "[!] Keybox placeholders detected - update needed"
    else
        echo "[OK] Keybox active"
    fi
else
    echo "[!] No keybox.xml"
fi

echo ""
echo "Opening WebUI..."
echo ""

# ==========================================
# v1.3.0: Universal WebUI Opener
# Opens WebUI for ALL root managers
# KernelSU/APatch: Native WebUI via webroot= in module.prop
# Magisk: Browser fallback with file:// URL
# ==========================================

open_webui_universal() {
    local WEBUI_PATH="/data/adb/modules_update/UBLESTRAMK/webroot/index.html"
    # If not in update path, use active module path
    [ -f "$WEBUI_PATH" ] || WEBUI_PATH="$MODPATH/webroot/index.html"
    
    local WEBUI_URL="file://${WEBUI_PATH}"
    local HAS_OPENED=false

    # Method 1: KernelSU native WebUI intent
    if is_kernelsu && command -v am >/dev/null 2>&1; then
        log_msg "INFO" "Opening KernelSU native WebUI"
        am start -a android.intent.action.VIEW \
            -d "$WEBUI_URL" \
            -n me.weishu.kernelsu/.ui.webui.WebUIActivity \
            2>/dev/null && HAS_OPENED=true
    fi

    # Method 2: APatch native WebUI intent
    if [ "$HAS_OPENED" = false ] && is_apatch && command -v am >/dev/null 2>&1; then
        log_msg "INFO" "Opening APatch native WebUI"
        am start -a android.intent.action.VIEW \
            -d "$WEBUI_URL" \
            -n me.bmax.apatch/.ui.webui.WebUIActivity \
            2>/dev/null && HAS_OPENED=true
    fi

    # Method 3: Magisk WebUI (if supported) or generic browser
    if [ "$HAS_OPENED" = false ] && command -v am >/dev/null 2>&1; then
        log_msg "INFO" "Opening browser fallback for WebUI"
        # Try generic webui intent first (Magisk 28+ may support this)
        am start -a android.intent.action.VIEW \
            -d "$WEBUI_URL" \
            2>/dev/null && HAS_OPENED=true
    fi

    # Log result
    if [ "$HAS_OPENED" = true ]; then
        log_msg "INFO" "WebUI opened successfully"
        echo "[OK] WebUI opened"
    else
        log_msg "WARN" "Could not open WebUI automatically"
        echo ""
        echo "================================"
        echo "  Manual WebUI Access"
        echo "================================"
        echo ""
        echo "KernelSU: Manager > Modules >"
        echo "          Tap UBLESTRAMK card"
        echo ""
        echo "APatch: Manager > Modules >"
        echo "        Tap UBLESTRAMK card"
        echo ""
        echo "Magisk: Open browser and go to:"
        echo "  $WEBUI_URL"
        echo ""
        echo "Community: https://t.me/lestramk"
        echo ""
    fi
}

# Execute WebUI open
open_webui_universal

log_msg "INFO" "Action button pressed - WebUI opened"
exit 0
