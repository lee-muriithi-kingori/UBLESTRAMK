#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Action Script
# Quick actions from Magisk/KernelSU Manager
#
# CHANGES (v1.1.0):
# - Added keybox update action
# - Added config reload action
# - Enhanced status output
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

LOG_FILE="/data/local/tmp/UBLESTRAMK.log"

echo "================================"
echo "  UBLESTRAMK Quick Actions"
echo "  Version: $(get_version)"
echo "================================"
echo ""
echo "Select action:"
echo ""
echo "  [1] Apply hiding now"
echo "  [2] Update keybox"
echo "  [3] Check keybox status"
echo "  [4] Reload configuration"
echo "  [5] View recent logs"
echo "  [6] Open WebUI (info)"
echo ""
echo "  [0] Exit"
echo ""
echo -n "Choice: "

read choice

case "$choice" in
    1)
        echo ""
        echo "Applying root hiding..."
        spoof_bootloader_locked
        hide_build_properties
        spoof_keybox_properties
        hide_keystore_traces
        echo "Done! Root hiding applied."
        log_msg "INFO" "Manual hiding applied via action button"
        ;;
    2)
        echo ""
        if [ -f "$MODPATH/keybox_updater.sh" ]; then
            echo "Updating keybox..."
            sh "$MODPATH/keybox_updater.sh" --force
            echo "Keybox update completed."
        else
            echo "Keybox updater not found!"
        fi
        ;;
    3)
        echo ""
        if [ -f "$MODPATH/keybox.xml" ]; then
            echo "Keybox Status:"
            echo "--------------"
            local has_placeholders=$(grep -c "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
            local kb_size=$(stat -c%s "$MODPATH/keybox.xml" 2>/dev/null)
            echo "File: $MODPATH/keybox.xml"
            echo "Size: ${kb_size} bytes"
            echo "Status: $([ "$has_placeholders" -gt 0 ] && echo 'TEMPLATE (needs real keys)' || echo 'CONFIGURED')"
            echo ""
            echo "Source: $(get_keybox_source_type)"
            echo "Attestation: $(get_attestation_mode)"
            echo "Security Level: $(get_security_level)"
        else
            echo "No keybox.xml found!"
        fi
        ;;
    4)
        echo ""
        echo "Reloading configuration..."
        if [ -f "$MODPATH/update_service_addon.sh" ]; then
            . "$MODPATH/update_service_addon.sh"
            ensure_webui_config
        fi
        # Re-apply settings
        spoof_keybox_properties
        hide_build_properties
        echo "Configuration reloaded."
        log_msg "INFO" "Configuration reloaded via action button"
        ;;
    5)
        echo ""
        echo "Recent logs (last 30 lines):"
        echo "----------------------------"
        tail -30 "$LOG_FILE" 2>/dev/null || echo "No logs available"
        ;;
    6)
        echo ""
        echo "WebUI Access:"
        echo "-------------"
        echo "For KernelSU: Open KernelSU Manager >"
        echo "  Modules > UBLESTRAMK > Tap module card"
        echo ""
        echo "For Magisk: Use a WebUI-compatible Magisk"
        echo "  build or access via browser at:"
        echo "  file:///data/adb/modules/UBLESTRAMK/webroot/"
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac

echo ""
echo "Press Enter to continue..."
read
echo "Returning to menu..."
sh "$0"
