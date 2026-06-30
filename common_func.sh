#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Common Functions
# Universal Boot-Lock Evasion & Stealth Root Admin Module
# Author: lee-muriithi-kingori
# Version: v1.1.0
#
# CHANGES (v1.1.0):
# - Added read_config() to read module configuration files
# - Added write_config() to write module configuration files
# - Enhanced keybox functions with source awareness
# - Added webui configuration helpers
#
# CHANGES (v1.0.0):
# - Added keybox/keystore attestation spoofing functions
# - Enhanced monitor_target_apps() for keybox attestation
# - Added keystore backend property spoofing (TEE/StrongBox)
#
# CHANGES (v0.9.1-beta):
# - Added PID-based app state cache to monitor loop
# - Removed all 'export -f' bashisms
# - Fixed is_magisk() to not rely on deprecated /sbin paths
# ==========================================

MODPATH="${0%/*}"
SKIPDELPROP=false
[ -f "$MODPATH/skipdelprop" ] && SKIPDELPROP=true

# Logging
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"
LOG_ENABLED=true

log_msg() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ "$LOG_ENABLED" = true ]; then
        echo "[$timestamp] [$level] UBLESTRAMK: $msg" >> "$LOG_FILE" 2>/dev/null
    fi
    log -t "UBLESTRAMK" "[$level] $msg" 2>/dev/null
}

# ==========================================
# v1.1.0: Configuration Management
# ==========================================

# Read a configuration value
read_config() {
    local key="$1"
    local default_value="${2:-}"
    local config_file="$MODPATH/.${key}"
    
    if [ -f "$config_file" ]; then
        cat "$config_file" 2>/dev/null
    else
        echo "$default_value"
    fi
}

# Write a configuration value
write_config() {
    local key="$1"
    local value="$2"
    local config_file="$MODPATH/.${key}"
    
    echo "$value" > "$config_file"
    chmod 644 "$config_file" 2>/dev/null
}

# Get keybox source type
get_keybox_source_type() {
    read_config "keybox_source_type" "default"
}

# Set keybox source type
set_keybox_source_type() {
    write_config "keybox_source_type" "$1"
}

# Get keybox source URL (for custom_url type)
get_keybox_source_url() {
    read_config "keybox_source_url" ""
}

# Set keybox source URL
set_keybox_source_url() {
    write_config "keybox_source_url" "$1"
}

# Get attestation mode
get_attestation_mode() {
    read_config "attestation_mode" "spoof"
}

# Set attestation mode
set_attestation_mode() {
    write_config "attestation_mode" "$1"
}

# Get security level
get_security_level() {
    read_config "keybox_security_level" "tee"
}

# Set security level
set_security_level() {
    write_config "keybox_security_level" "$1"
}

# Check if feature is enabled
is_feature_enabled() {
    local feature="$1"
    local value=$(read_config "$feature" "1")
    [ "$value" = "1" ]
}

# ==========================================
# Property helpers
# ==========================================

# resetprop_if_diff <prop name> <expected value>
resetprop_if_diff() {
    local NAME="$1"
    local EXPECTED="$2"
    local CURRENT="$(resetprop "$NAME" 2>/dev/null)"

    if [ -z "$CURRENT" ] || [ "$CURRENT" != "$EXPECTED" ]; then
        resetprop -n "$NAME" "$EXPECTED" 2>/dev/null
        log_msg "INFO" "Set $NAME=$EXPECTED (was: $CURRENT)"
    fi
}

# resetprop_if_match <prop name> <value match string> <new value>
resetprop_if_match() {
    local NAME="$1"
    local CONTAINS="$2"
    local VALUE="$3"
    local CURRENT="$(resetprop "$NAME" 2>/dev/null)"

    if [ -n "$CURRENT" ] && echo "$CURRENT" | grep -q "$CONTAINS"; then
        resetprop -n "$NAME" "$VALUE" 2>/dev/null
        log_msg "INFO" "Matched $NAME containing '$CONTAINS', set to $VALUE"
    fi
}

# delprop_if_exist <prop name>
delprop_if_exist() {
    local NAME="$1"
    local CURRENT="$(resetprop "$NAME" 2>/dev/null)"

    if [ -n "$CURRENT" ] && [ "$SKIPDELPROP" = false ]; then
        resetprop --delete "$NAME" 2>/dev/null
        log_msg "INFO" "Deleted property $NAME (was: $CURRENT)"
    fi
}

# ==========================================
# Root solution detection
# ==========================================

# Check if running on KernelSU
is_kernelsu() {
    [ -n "${KSU}" ] && [ "${KSU}" = "true" ]
}

# Check if running on Magisk
is_magisk() {
    [ -n "${MAGISK_VER_CODE}" ] || [ -f "/data/adb/magisk/magisk" ]
}

# Check if running on APatch
is_apatch() {
    [ -n "${APATCH}" ] && [ "${APATCH}" = "true" ]
}

# Detect root solution
detect_root_solution() {
    if is_kernelsu; then
        echo "kernelsu"
    elif is_apatch; then
        echo "apatch"
    elif is_magisk; then
        echo "magisk"
    else
        echo "unknown"
    fi
}

# Get module version
get_version() {
    grep "^version=" "$MODPATH/module.prop" | cut -d'=' -f2
}

# ==========================================
# App monitoring
# ==========================================

# Check if app is running - with PID cache
is_app_running() {
    local pkg="$1"
    local cache_var="CACHE_PID_${pkg}"
    local cached_pid=""
    eval "cached_pid=\$$cache_var"

    if [ -n "$cached_pid" ] && [ -d "/proc/$cached_pid" ]; then
        if [ -r "/proc/$cached_pid/cmdline" ]; then
            local cmdline="$(tr '\0' ' ' < "/proc/$cached_pid/cmdline" 2>/dev/null)"
            if echo "$cmdline" | grep -q "$pkg"; then
                return 0
            fi
        fi
    fi

    local new_pid="$(pidof "$pkg" 2>/dev/null)"
    if [ -n "$new_pid" ]; then
        eval "$cache_var='$new_pid'"
        return 0
    fi

    eval "$cache_var=''"
    return 1
}

# Check if UID belongs to a user app
is_user_app() {
    local uid="$1"
    local appid=$((uid % 100000))
    [ "$appid" -ge 10000 ] && [ "$appid" -le 19999 ]
}

# Check if an app uses hardware attestation
is_attestation_app() {
    local pkg="$1"
    case "$pkg" in
        com.ubercab.driver|com.ubercab|com.ubercab.eats|ee.mtakso.client|\
        com.chase.sig.android|com.bankofamerica.cashpromobile|com.wf.wellsfargomobile|\
        com.paypal.android.p2pmobile|com.venmo|\
        com.safaricom.mpesa.lifestyle|com.equitybank.equityjiunge|\
        com.kcbgroup.kcbpip|co.ke.coopbank|za.co.absa.africa.android|\
        com.opay.ng|com.transsnet.palmpay|com.kudabank.app|\
        com.chippercash|com.revolut.revolut|com.transferwise.android|\
        com.netflix.mediaclient|com.nianticlabs.pokemongo|com.microsoft.teams)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ==========================================
# Bootloader spoofing
# ==========================================

# Spoof all bootloader-related properties
spoof_bootloader_locked() {
    log_msg "INFO" "Spoofing locked bootloader state"
    
    # Only spoof if enabled in config
    if ! is_feature_enabled "spoof_bootloader"; then
        log_msg "INFO" "Bootloader spoofing disabled in settings"
        return 0
    fi
    
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    
    resetprop_if_diff ro.boot.warranty_bit 0
    resetprop_if_diff ro.warranty_bit 0
    resetprop_if_diff ro.vendor.boot.warranty_bit 0
    resetprop_if_diff ro.vendor.warranty_bit 0
    
    resetprop_if_diff ro.boot.realmebootstate green
    resetprop_if_diff ro.boot.realme.lockstate 1
    
    resetprop_if_diff ro.is_ever_orange 0
    
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.secureboot 1
    resetprop_if_diff vendor.boot.flash.locked 1
    
    resetprop_if_diff ro.boot.knox 0
    resetprop_if_diff ro.config.knox 0
    resetprop_if_diff ro.secureboot.devicelock 1
    
    log_msg "INFO" "Bootloader lock spoofing applied"
}

# ==========================================
# Keybox/Keystore spoofing
# ==========================================

# Spoof keybox/keystore hardware attestation properties
spoof_keybox_properties() {
    log_msg "INFO" "Spoofing keybox/keystore attestation properties"
    
    # Get configured security level
    local sec_level=$(get_security_level)
    local keystore_backend="teetz"
    local keymint_backend="trusty"
    
    case "$sec_level" in
        strongbox)
            keystore_backend="strongbox"
            keymint_backend="strongbox"
            ;;
        software)
            keystore_backend="software"
            keymint_backend="software"
            ;;
        *)
            # tee is default
            ;;
    esac
    
    # Keystore backend
    resetprop_if_diff ro.hardware.keystore "$keystore_backend"
    resetprop_if_diff ro.security.keystore.deserializer_type "$sec_level"
    
    # KeyMint/Gatekeeper backend
    resetprop_if_diff ro.hardware.keymint "$keymint_backend"
    resetprop_if_diff ro.hardware.gatekeeper "$keystore_backend"
    resetprop_if_diff ro.hardware.bootctrl default
    
    # Crypto state - encrypted device
    resetprop_if_diff ro.crypto.state encrypted
    resetprop_if_diff ro.crypto.type file
    
    # Remove any indicators of software-only keystore
    delprop_if_exist ro.hardware.keystore.rsa
    delprop_if_exist ro.security.keystore.sw
    
    log_msg "INFO" "Keybox properties spoofing applied ($sec_level backend)"
}

# Set up keybox environment for Zygisk native hooks
setup_keybox_environment() {
    local security_level="${1:-1}"
    log_msg "INFO" "Setting up keybox environment (security_level=$security_level)"
    
    # Write security level to a file that Zygisk can read
    local sec_level=$(get_security_level)
    local sec_level_num=1
    case "$sec_level" in
        strongbox) sec_level_num=2 ;;
        software) sec_level_num=0 ;;
        *) sec_level_num=1 ;;
    esac
    
    echo "$sec_level_num" > "$MODPATH/.keybox_security_level" 2>/dev/null
    
    # Set environment variable for child processes
    export UBLESTRAMK_KEYBOX_SECURITY_LEVEL="$sec_level_num"
    
    # Check for user-provided or downloaded keybox.xml
    if [ -f "$MODPATH/keybox.xml" ]; then
        export UBLESTRAMK_KEYBOX_XML="$MODPATH/keybox.xml"
        log_msg "INFO" "Keybox XML configured: $MODPATH/keybox.xml"
        
        # Check if it's still a template
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "keybox.xml contains PLACEHOLDER values"
        fi
    fi
}

# Hide keystore-related root indicators
hide_keystore_traces() {
    log_msg "INFO" "Hiding keystore traces"
    
    # Only hide if enabled in config
    if ! is_feature_enabled "hide_keystore"; then
        log_msg "INFO" "Keystore hiding disabled in settings"
        return 0
    fi
    
    # Delete any magisk/KSU-specific keystore injection markers
    delprop_if_exist ro.magisk.keystore
    delprop_if_exist ro.ksu.keystore
    delprop_if_exist ro.apatch.keystore
    
    # Ensure consistent state between keystore and bootloader props
    local vb_state="$(resetprop ro.boot.verifiedbootstate 2>/dev/null)"
    if [ "$vb_state" = "green" ] || [ "$vb_state" = "locked" ]; then
        # If bootloader claims locked, keystore must report TEE/StrongBox
        local sec_level=$(get_security_level)
        local keystore_backend="teetz"
        [ "$sec_level" = "strongbox" ] && keystore_backend="strongbox"
        resetprop_if_diff ro.hardware.keystore "$keystore_backend"
    fi
    
    log_msg "INFO" "Keystore traces hidden"
}

# ==========================================
# Build properties hiding
# ==========================================

# Hide root-specific build properties
hide_build_properties() {
    log_msg "INFO" "Hiding build properties"
    
    # Only spoof if enabled in config
    if ! is_feature_enabled "spoof_properties"; then
        log_msg "INFO" "Property spoofing disabled in settings"
        return 0
    fi
    
    for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.tags' || true); do
        resetprop_if_diff "$PROP" "release-keys"
    done
    
    for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.type' || true); do
        resetprop_if_diff "$PROP" "user"
    done
    
    resetprop_if_diff ro.adb.secure 1
    resetprop_if_diff ro.debuggable 0
    resetprop_if_diff ro.force.debuggable 0
    resetprop_if_diff ro.secure 1
    
    delprop_if_exist ro.build.selinux
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
    
    resetprop_if_match ro.boot.mode recovery unknown
    resetprop_if_match ro.bootmode recovery unknown
    resetprop_if_match vendor.boot.mode recovery unknown
    
    resetprop_if_diff ro.boot.selinux enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0
    
    log_msg "INFO" "Build properties hidden"
}

# ==========================================
# Magisk trace hiding
# ==========================================

# Hide Magisk-specific files and paths
hide_magisk_traces() {
    log_msg "INFO" "Hiding Magisk traces"
    
    local found_target=false
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        case "$pkg" in
            ""|\#*) continue ;;
        esac
        if is_app_running "$pkg"; then
            found_target=true
            break
        fi
    done < "$MODPATH/target_apps.txt"
    
    if [ "$found_target" = true ]; then
        log_msg "INFO" "Target app detected - applying enhanced hiding"
        resetprop_if_diff persist.sys.adb.notify 0
        delprop_if_exist service.adb.tcp.port
    fi
}

# ==========================================
# Target app monitoring
# ==========================================

# Enhanced monitor with keybox attestation support
monitor_target_apps() {
    local last_state=""
    local sleep_interval=10
    local keybox_setup_done=false
    
    while true; do
        if ! is_boot_completed; then
            sleep 5
            continue
        fi
        
        # Setup keybox environment once after boot
        if [ "$keybox_setup_done" = false ]; then
            setup_keybox_environment 1
            keybox_setup_done=true
        fi
        
        local current_state=""
        local found_any=false
        local found_attestation_app=false
        
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            case "$pkg" in
                ""|\#*) continue ;;
            esac
            if is_app_running "$pkg"; then
                current_state="${current_state}${pkg};"
                found_any=true
                
                # Check if this is an attestation-using app
                if is_attestation_app "$pkg"; then
                    found_attestation_app=true
                fi
            fi
        done < "$MODPATH/target_apps.txt"
        
        # Adaptive sleep
        if [ "$found_any" = true ]; then
            sleep_interval=3
        else
            sleep_interval=10
        fi
        
        if [ "$current_state" != "$last_state" ]; then
            if [ -n "$current_state" ]; then
                log_msg "INFO" "Target apps detected: $current_state"
                spoof_bootloader_locked
                hide_build_properties
                hide_magisk_traces
                
                # Apply keybox hiding for attestation apps
                if [ "$found_attestation_app" = true ]; then
                    log_msg "INFO" "Attestation app detected - applying keybox spoofing"
                    spoof_keybox_properties
                    hide_keystore_traces
                fi
            fi
            last_state="$current_state"
        fi
        
        sleep "$sleep_interval"
    done
}

# ==========================================
# Boot utilities
# ==========================================

# Check if device has boot completed
is_boot_completed() {
    [ "$(getprop sys.boot_completed)" = "1" ]
}

# Wait for boot completion
wait_for_boot() {
    local count=0
    while [ "$count" -lt 120 ]; do
        if is_boot_completed; then
            log_msg "INFO" "Boot completed detected"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    log_msg "WARN" "Timeout waiting for boot completion"
    return 1
}
