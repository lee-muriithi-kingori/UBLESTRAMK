#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Action Script
# Opens the WebUI for module configuration
#
# CHANGES (v1.2.0):
# - Action button now opens WebUI directly instead of terminal menu
# - Added browser fallback for root managers without WebUI support
# - Added community channel link
# - Added boot verification status display
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

LOG_FILE="/data/local/tmp/UBLESTRAMK.log"

# Function to check if we can open WebUI
open_webui() {
    local webui_url="file:///data/adb/modules/UBLESTRAMK/webroot/index.html"
    local has_opened=false

    # Try to open via KernelSU WebUI intent
    if is_kernelsu; then
        # KernelSU Manager handles webroot= module.prop automatically
        # when user taps the module card - this script is the fallback
        log_msg "INFO" "KernelSU detected - attempting WebUI open"
        
        # Try to open via am start with KernelSU WebUI intent
        if command -v am >/dev/null 2>&1; then
            # Try KernelSU Manager WebUI intent
            am start -a android.intent.action.VIEW \
                -d "$webui_url" \
                -n me.weishu.kernelsu/.ui.webui.WebUIActivity \
                2>/dev/null && has_opened=true
        fi
    fi

    # Try APatch WebUI intent
    if [ "$has_opened" = false ] && is_apatch; then
        log_msg "INFO" "APatch detected - attempting WebUI open"
        
        if command -v am >/dev/null 2>&1; then
            am start -a android.intent.action.VIEW \
                -d "$webui_url" \
                -n me.bmax.apatch/.ui.webui.WebUIActivity \
                2>/dev/null && has_opened=true
        fi
    fi

    # Generic fallback - open in default browser
    if [ "$has_opened" = false ]; then
        log_msg "INFO" "Attempting browser fallback for WebUI"
        
        if command -v am >/dev/null 2>&1; then
            am start -a android.intent.action.VIEW \
                -d "$webui_url" \
                2>/dev/null && has_opened=true
        fi
    fi

    if [ "$has_opened" = true ]; then
        log_msg "INFO" "WebUI opened successfully"
        echo "Opening UBLESTRAMK WebUI..."
    else
        log_msg "WARN" "Could not open WebUI automatically"
        echo ""
        echo "================================"
        echo "  UBLESTRAMK WebUI Access"
        echo "================================"
        echo ""
        echo "For KernelSU: Open KernelSU Manager >"
        echo "  Modules > UBLESTRAMK > Tap module card"
        echo ""
        echo "For Magisk/APatch: Open your browser at:"
        echo "  $webui_url"
        echo ""
        echo "Community: https://t.me/lestramk"
        echo ""
        echo "Press Enter to continue..."
        read
    fi
}

# Show module status and open WebUI
echo "================================"
echo "  UBLESTRAMK"
echo "  Version: $(get_version)"
echo "  Root: $(detect_root_solution)"
echo "================================"
echo ""

# Check boot verifier status
if [ -f "$MODPATH/.post_fs_data_done" ]; then
    echo "[OK] Module initialized successfully"
else
    echo "[!] Module initialization may be incomplete"
    echo "    Consider checking logs if issues occur"
fi

# Show keybox status
if [ -f "$MODPATH/keybox.xml" ]; then
    local kb_has_ph=$(grep -c "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
    if [ "$kb_has_ph" -gt 0 ]; then
        echo "[!] Keybox has placeholder values - update recommended"
    else
        echo "[OK] Keybox configured"
    fi
else
    echo "[!] No keybox.xml found"
fi

echo ""
echo "Opening WebUI..."
echo ""

open_webui

log_msg "INFO" "Action button triggered - WebUI opened"
exit 0
