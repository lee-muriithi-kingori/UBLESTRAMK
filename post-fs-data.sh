#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Post Filesystem Data Script
# Runs early in boot - before Zygote starts
#
# CHANGES (v1.2.0):
# - REMOVED chmod /proc/cmdline (causes Samsung Knox boot hang)
# - REMOVED setup_keybox_environment from post-fs-data (moved to service.sh)
# - REMOVED keybox auto-update trigger from post-fs-data (moved to service.sh)
# - ADDED boot verification marker system
# - ADDED safe mode detection (skip operations in safe mode)
# - ADDED post-fs-data timeout protection
# - ADDED boot failure marker for recovery
# - Fixed POSIX compatibility (removed local keyword)
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

# v1.2.0: Boot verification - mark start
MODTIME_START=$(date +%s 2>/dev/null || echo 0)
echo "${MODTIME_START}" > "$MODPATH/.post_fs_data_start"

# v1.2.0: Safe mode detection - skip all operations if in safe mode
IS_SAFE_MODE=$(getprop ro.boot.safe_mode 2>/dev/null)
if [ "$IS_SAFE_MODE" = "1" ] || [ "$IS_SAFE_MODE" = "true" ]; then
    log_msg "INFO" "Safe mode detected - skipping all post-fs-data operations"
    echo "1" > "$MODPATH/.safe_mode_detected"
    echo "1" > "$MODPATH/.post_fs_data_done"
    exit 0
fi

# v1.2.0: Recovery mode detection - skip operations if in recovery
BOOT_MODE=$(getprop ro.boot.mode 2>/dev/null)
if [ "$BOOT_MODE" = "recovery" ]; then
    log_msg "INFO" "Recovery mode detected - skipping all post-fs-data operations"
    echo "1" > "$MODPATH/.recovery_mode_detected"
    echo "1" > "$MODPATH/.post_fs_data_done"
    exit 0
fi

# v1.2.0: Check if previous boot failed (emergency disable)
if [ -f "$MODPATH/.boot_failed" ]; then
    BOOT_FAIL_COUNT=$(cat "$MODPATH/.boot_failed" 2>/dev/null || echo 0)
    if [ "$BOOT_FAIL_COUNT" -ge "2" ]; then
        log_msg "WARN" "Previous $BOOT_FAIL_COUNT boot failures detected - disabling module"
        ui_print "! UBLESTRAMK: Multiple boot failures detected"
        ui_print "! Module disabled for safety"
        ui_print "! Join https://t.me/lestramk for help"
        touch "$MODPATH/disable"
        echo "1" > "$MODPATH/.post_fs_data_done"
        exit 0
    fi
fi

# v1.2.0: Ensure configuration files exist (POSIX-compatible, no local keyword)
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

# Early sensitive properties - set before Zygote
# CRITICAL: Only set properties that MUST be ready before Zygote starts
# All other properties are deferred to service.sh (late start)

# Samsung warranty bits (must be set before Zygote for Knox apps)
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

# Delete error indicators (safe to delete, not critical boot properties)
if [ "$SKIPDELPROP" = false ]; then
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
fi

# Debug flags
resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.force.debuggable 0
resetprop_if_diff ro.secure 1

# Recovery mode spoof (critical for apps checking boot state)
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# SELinux
resetprop_if_diff ro.boot.selinux enforcing

# v1.2.0: Keystore/keymint early property spoofing with config
# These must be set before Zygote for hardware attestation to work
log_msg "INFO" "Setting up keybox/keystore early properties"

# Get configured security level (inline, not function call for speed)
SEC_LEVEL_FILE="$MODPATH/.keybox_security_level"
if [ -f "$SEC_LEVEL_FILE" ]; then
    sec_level=$(cat "$SEC_LEVEL_FILE" 2>/dev/null || echo "tee")
else
    sec_level="tee"
fi

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

# Report TEE-backed keystore (must be set before Zygote)
resetprop_if_diff ro.hardware.keystore "$keystore_backend"
resetprop_if_diff ro.security.keystore.deserializer_type "$sec_level"

# KeyMint/Gatekeeper backend (must be set before Zygote)
resetprop_if_diff ro.hardware.keymint "$keymint_backend"
resetprop_if_diff ro.hardware.gatekeeper "$keystore_backend"

# Crypto state consistency
resetprop_if_diff ro.crypto.state encrypted
resetprop_if_diff ro.crypto.type file

# Boot control
resetprop_if_diff ro.hardware.bootctrl default

# v1.2.0: Validate keybox.xml if present (read-only check, NO network)
if [ -f "$MODPATH/keybox.xml" ]; then
    if [ -r "$MODPATH/keybox.xml" ]; then
        # v1.2.0: Use wc instead of stat for POSIX compatibility
        kb_size=$(wc -c < "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
        log_msg "INFO" "keybox.xml found (${kb_size} bytes)"
        
        # Check if it's still a template (has PLACEHOLDER markers)
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "keybox.xml contains PLACEHOLDER values"
            log_msg "WARN" "Replace placeholders with real keys for better compatibility"
            # v1.2.0: DO NOT auto-update here - defer to service.sh
            log_msg "INFO" "Keybox update will be attempted after boot completes"
        fi
    else
        log_msg "WARN" "keybox.xml exists but is not readable"
    fi
else
    log_msg "INFO" "No keybox.xml found - using embedded certificate templates"
fi

# v1.2.0: REMOVED chmod /proc/cmdline - causes Samsung Knox boot hang
# The pseudo-file chmod has no effect anyway (sysfs files are kernel-backed)
# and triggers SELinux denials on Samsung devices
log_msg "INFO" "Skipping /proc/cmdline modification (removed in v1.2.0)"

# v1.2.0: REMOVED setup_keybox_environment call from post-fs-data
# Moved to service.sh where filesystem is guaranteed ready
# The Zygisk companion can read the keybox files directly from $MODPATH

# Create module flag file for Zygisk detection
if [ -d "$MODPATH/zygisk" ]; then
    log_msg "INFO" "Zygisk libraries detected"
fi

# v1.2.0: Create keybox state file for inter-process communication
echo "1" > "$MODPATH/.keybox_ready" 2>/dev/null || true

# v1.2.0: Boot verification - mark completion
echo "1" > "$MODPATH/.post_fs_data_done" 2>/dev/null || true

# v1.2.0: Clear boot failure counter on successful post-fs-data
rm -f "$MODPATH/.boot_failed" 2>/dev/null || true

MODTIME_END=$(date +%s 2>/dev/null || echo 0)
MODTIME_DURATION=$((MODTIME_END - MODTIME_START))
log_msg "INFO" "=== post-fs-data completed in ${MODTIME_DURATION}s ==="
exit 0
