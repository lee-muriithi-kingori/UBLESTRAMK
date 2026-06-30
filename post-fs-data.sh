#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Post Filesystem Data Script
# Runs early in boot - before Zygote starts
#
# CHANGES (v1.1.0):
# - Added webui configuration file initialization
# - Added keybox source validation
# - Enhanced keystore property spoofing with config awareness
#
# CHANGES (v1.0.0):
# - Added keybox/keystore early property spoofing
# - Validates keybox.xml exists and is readable
# - Added keybox environment setup for Zygisk companion
#
# CHANGES (v0.9.1-beta):
# - Removed non-standard ro.boot.veritymode.managed property
# - Removed no-op chmod calls on sysfs pseudo-files
# ==========================================

MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

log_msg "INFO" "=== UBLESTRAMK post-fs-data starting ==="
log_msg "INFO" "Version: $(get_version)"
log_msg "INFO" "Root solution: $(detect_root_solution)"

# v1.1.0: Ensure configuration files exist
ensure_configs() {
    [ ! -f "$MODPATH/.keybox_source_type" ] && echo "default" > "$MODPATH/.keybox_source_type"
    [ ! -f "$MODPATH/.keybox_auto_update" ] && echo "1" > "$MODPATH/.keybox_auto_update"
    [ ! -f "$MODPATH/.keybox_update_interval" ] && echo "24" > "$MODPATH/.keybox_update_interval"
    [ ! -f "$MODPATH/.attestation_mode" ] && echo "spoof" > "$MODPATH/.attestation_mode"
    [ ! -f "$MODPATH/.keybox_security_level" ] && echo "tee" > "$MODPATH/.keybox_security_level"
    [ ! -f "$MODPATH/.spoof_bootloader" ] && echo "1" > "$MODPATH/.spoof_bootloader"
    [ ! -f "$MODPATH/.spoof_properties" ] && echo "1" > "$MODPATH/.spoof_properties"
    [ ! -f "$MODPATH/.hide_keystore" ] && echo "1" > "$MODPATH/.hide_keystore"
    chmod 644 $MODPATH/.* 2>/dev/null
}
ensure_configs

# Early sensitive properties - set before Zygote

# Samsung warranty bits
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0

# Realme boot state
resetprop_if_diff ro.boot.realmebootstate green

# OnePlus
resetprop_if_diff ro.is_ever_orange 0

# Microsoft/General build tags
for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.tags' || true); do
    resetprop_if_diff "$PROP" "release-keys"
done

# Build type
for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.type' || true); do
    resetprop_if_diff "$PROP" "user"
done

# ADB security
resetprop_if_diff ro.adb.secure 1

# Delete error indicators
if [ "$SKIPDELPROP" = false ]; then
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
fi

# Debug flags
resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.force.debuggable 0
resetprop_if_diff ro.secure 1

# Recovery mode spoof
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# SELinux
resetprop_if_diff ro.boot.selinux enforcing

# v1.1.0: Keystore/keymint early property spoofing with config
log_msg "INFO" "Setting up keybox/keystore early properties"

# Get configured security level
sec_level=$(get_security_level)
keystore_backend="teetz"
keymint_backend="trusty"

case "$sec_level" in
    strongbox)
        keystore_backend="strongbox"
        keymint_backend="strongbox"
        ;;
    software)
        keystore_backend="software"
        keymint_backend="software"
        ;;
esac

# Report TEE-backed keystore
resetprop_if_diff ro.hardware.keystore "$keystore_backend"
resetprop_if_diff ro.security.keystore.deserializer_type "$sec_level"

# KeyMint/Gatekeeper backend
resetprop_if_diff ro.hardware.keymint "$keymint_backend"
resetprop_if_diff ro.hardware.gatekeeper "$keystore_backend"

# Crypto state consistency
resetprop_if_diff ro.crypto.state encrypted
resetprop_if_diff ro.crypto.type file

# Boot control
resetprop_if_diff ro.hardware.bootctrl default

# v1.1.0: Validate keybox.xml if present
if [ -f "$MODPATH/keybox.xml" ]; then
    if [ -r "$MODPATH/keybox.xml" ]; then
        local kb_size=$(stat -c%s "$MODPATH/keybox.xml" 2>/dev/null)
        log_msg "INFO" "keybox.xml found (${kb_size} bytes)"
        
        # Check if it's still a template (has PLACEHOLDER markers)
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "keybox.xml contains PLACEHOLDER values - attestation will use embedded certificates"
            log_msg "WARN" "Replace placeholders with real keys for better compatibility"
            
            # v1.1.0: If auto-update is enabled and source is default, try to fetch real keys
            local source_type=$(get_keybox_source_type)
            local auto_update=$(read_config "keybox_auto_update" "1")
            if [ "$source_type" = "default" ] && [ "$auto_update" = "1" ] && [ -f "$MODPATH/keybox_updater.sh" ]; then
                log_msg "INFO" "Attempting to fetch updated keybox..."
                sh "$MODPATH/keybox_updater.sh" --force >/dev/null 2>&1 &
            fi
        fi
    else
        log_msg "WARN" "keybox.xml exists but is not readable"
    fi
else
    log_msg "INFO" "No keybox.xml found - using embedded certificate templates"
fi

# Set up keybox environment for Zygisk
setup_keybox_environment 1

# Clean any root indicators in /proc
if [ -d /proc/1 ]; then
    if [ -r /proc/cmdline ]; then
        chmod 640 /proc/cmdline 2>/dev/null || true
    fi
fi

# Create module flag file for Zygisk detection
if [ -d "$MODPATH/zygisk" ]; then
    log_msg "INFO" "Zygisk libraries detected"
fi

# v1.1.0: Create keybox state file for inter-process communication
echo "1" > "$MODPATH/.keybox_ready" 2>/dev/null

log_msg "INFO" "=== post-fs-data completed ==="
