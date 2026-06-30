#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Post Filesystem Data Script
# Runs early in boot - before Zygote starts
#
# CHANGES (v1.0.0):
# - Added keybox/keystore early property spoofing
#   Sets keystore backend properties before Zygote initializes
#   This ensures apps see consistent attestation capability
# - Added ro.hardware.keystore spoofing
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

# v1.0.0: Keystore/keymint early property spoofing
# These must be set before Zygote starts to ensure keystore
# service initializes with the spoofed values
log_msg "INFO" "Setting up keybox/keystore early properties"

# Report TEE-backed keystore
resetprop_if_diff ro.hardware.keystore teetz
resetprop_if_diff ro.security.keystore.deserializer_type tee

# KeyMint/Gatekeeper backend
resetprop_if_diff ro.hardware.keymint trusty
resetprop_if_diff ro.hardware.gatekeeper teetz

# Crypto state consistency
resetprop_if_diff ro.crypto.state encrypted
resetprop_if_diff ro.crypto.type file

# Boot control
resetprop_if_diff ro.hardware.bootctrl default

# v1.0.0: Validate keybox.xml if present
if [ -f "$MODPATH/keybox.xml" ]; then
    if [ -r "$MODPATH/keybox.xml" ]; then
        local kb_size=$(stat -c%s "$MODPATH/keybox.xml" 2>/dev/null)
        log_msg "INFO" "keybox.xml found (${kb_size} bytes)"
        
        # Check if it's still a template (has PLACEHOLDER markers)
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "keybox.xml contains PLACEHOLDER values - attestation will use embedded certificates"
            log_msg "WARN" "Replace placeholders with real keys for better compatibility"
        fi
    else
        log_msg "WARN" "keybox.xml exists but is not readable"
    fi
else
    log_msg "INFO" "No keybox.xml found - using embedded certificate templates"
fi

# v1.0.0: Set up keybox environment for Zygisk
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

# v1.0.0: Create keybox state file for inter-process communication
echo "1" > "$MODPATH/.keybox_ready" 2>/dev/null

log_msg "INFO" "=== post-fs-data completed ==="
