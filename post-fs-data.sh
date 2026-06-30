#!/system/bin/sh
# UBLESTRAMK Post-FS-Data Script v1.4.0
MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

log_msg "INFO" "=== post-fs-data v1.4.0 ==="

MODTIME_START=$(date +%s 2>/dev/null || echo 0)
echo "$MODTIME_START" > "$MODPATH/.post_fs_data_start"

IS_SAFE_MODE=$(getprop ro.boot.safe_mode 2>/dev/null)
if [ "$IS_SAFE_MODE" = "1" ] || [ "$IS_SAFE_MODE" = "true" ]; then
    log_msg "INFO" "Safe mode - skipping"
    echo "1" > "$MODPATH/.safe_mode_detected"
    echo "1" > "$MODPATH/.post_fs_data_done"
    exit 0
fi

BOOT_MODE=$(getprop ro.boot.mode 2>/dev/null)
if [ "$BOOT_MODE" = "recovery" ]; then
    log_msg "INFO" "Recovery mode - skipping"
    echo "1" > "$MODPATH/.recovery_mode_detected"
    echo "1" > "$MODPATH/.post_fs_data_done"
    exit 0
fi

if [ -f "$MODPATH/.boot_failed" ]; then
    BOOT_FAIL_COUNT=$(cat "$MODPATH/.boot_failed" 2>/dev/null || echo 0)
    if [ "$BOOT_FAIL_COUNT" -ge "2" ]; then
        log_msg "WARN" "Multiple boot failures - disabling"
        ui_print "! UBLESTRAMK: Boot failures detected"
        ui_print "! Module disabled for safety"
        ui_print "! Join https://t.me/lestramk"
        touch "$MODPATH/disable"
        echo "1" > "$MODPATH/.post_fs_data_done"
        exit 0
    fi
fi

ensure_configs() {
    [ ! -f "$MODPATH/.keybox_source_type" ] && echo "default" > "$MODPATH/.keybox_source_type"
    [ ! -f "$MODPATH/.keybox_auto_update" ] && echo "1" > "$MODPATH/.keybox_auto_update"
    [ ! -f "$MODPATH/.keybox_update_interval" ] && echo "24" > "$MODPATH/.keybox_update_interval"
    [ ! -f "$MODPATH/.attestation_mode" ] && echo "spoof" > "$MODPATH/.attestation_mode"
    [ ! -f "$MODPATH/.keybox_security_level" ] && echo "tee" > "$MODPATH/.keybox_security_level"
    [ ! -f "$MODPATH/.spoof_bootloader" ] && echo "1" > "$MODPATH/.spoof_bootloader"
    [ ! -f "$MODPATH/.spoof_properties" ] && echo "1" > "$MODPATH/.spoof_properties"
    [ ! -f "$MODPATH/.hide_keystore" ] && echo "1" > "$MODPATH/.hide_keystore"
    chmod 644 "$MODPATH/".* 2>/dev/null || true
}
ensure_configs

# Early properties
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0
resetprop_if_diff ro.boot.realmebootstate green
resetprop_if_diff ro.is_ever_orange 0

for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.tags' || true); do
    resetprop_if_diff "$PROP" "release-keys"
done
for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.type' || true); do
    resetprop_if_diff "$PROP" "user"
done
resetprop_if_diff ro.adb.secure 1

if [ "$SKIPDELPROP" = false ]; then
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
fi

resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.force.debuggable 0
resetprop_if_diff ro.secure 1

resetprop_if_match ro.boot.mode recovery boot
resetprop_if_match ro.bootmode recovery boot
resetprop_if_match vendor.boot.mode recovery boot

resetprop_if_diff ro.boot.selinux enforcing

# Keybox/keystore early properties
SEC_LEVEL_FILE="$MODPATH/.keybox_security_level"
if [ -f "$SEC_LEVEL_FILE" ]; then
    sec_level=$(cat "$SEC_LEVEL_FILE" 2>/dev/null || echo "tee")
else
    sec_level="tee"
fi
keystore_backend="teetz"
keymint_backend="trusty"
case "$sec_level" in
    strongbox) keystore_backend="strongbox"; keymint_backend="strongbox" ;;
    software) keystore_backend="software"; keymint_backend="software" ;;
esac

resetprop_if_diff ro.hardware.keystore "$keystore_backend"
resetprop_if_diff ro.security.keystore.deserializer_type "$sec_level"
resetprop_if_diff ro.hardware.keymint "$keymint_backend"
resetprop_if_diff ro.hardware.gatekeeper "$keystore_backend"
resetprop_if_diff ro.crypto.state encrypted
resetprop_if_diff ro.crypto.type file
resetprop_if_diff ro.hardware.bootctrl default

if [ -f "$MODPATH/keybox.xml" ]; then
    if [ -r "$MODPATH/keybox.xml" ]; then
        kb_size=$(wc -c < "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
        log_msg "INFO" "keybox.xml found (${kb_size} bytes)"
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "keybox.xml has PLACEHOLDER values"
        fi
    fi
fi

[ -d "$MODPATH/zygisk" ] && log_msg "INFO" "Zygisk libraries detected"

echo "1" > "$MODPATH/.keybox_ready" 2>/dev/null || true
echo "1" > "$MODPATH/.post_fs_data_done" 2>/dev/null || true
rm -f "$MODPATH/.boot_failed" 2>/dev/null || true

MODTIME_END=$(date +%s 2>/dev/null || echo 0)
MODTIME_DURATION=$((MODTIME_END - MODTIME_START))
log_msg "INFO" "=== post-fs-data done in ${MODTIME_DURATION}s ==="
exit 0
