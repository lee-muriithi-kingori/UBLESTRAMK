#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Common Functions
# Universal Boot-Lock Evasion & Stealth Root Admin Module
# Author: lee-muriithi-kingori
# Version: v0.9.0-beta
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

# Property helpers
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

# Check if running on KernelSU
is_kernelsu() {
    [ -n "${KSU}" ] && [ "${KSU}" = "true" ]
}

# Check if running on Magisk
is_magisk() {
    [ -n "${MAGISK_VER_CODE}" ] || [ -f "/sbin/.magisk/magisk" ] || [ -f "/system/bin/magisk" ]
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

# Check if app is running
is_app_running() {
    local pkg="$1"
    pidof "$pkg" >/dev/null 2>&1
}

# Check if UID belongs to a user app
is_user_app() {
    local uid="$1"
    local appid=$((uid % 100000))
    [ "$appid" -ge 10000 ] && [ "$appid" -le 19999 ]
}

# Spoof all bootloader-related properties
spoof_bootloader_locked() {
    log_msg "INFO" "Spoofing locked bootloader state"
    
    # Core bootloader properties
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    
    # Samsung-specific
    resetprop_if_diff ro.boot.warranty_bit 0
    resetprop_if_diff ro.warranty_bit 0
    resetprop_if_diff ro.vendor.boot.warranty_bit 0
    resetprop_if_diff ro.vendor.warranty_bit 0
    
    # Realme/Oppo
    resetprop_if_diff ro.boot.realmebootstate green
    resetprop_if_diff ro.boot.realme.lockstate 1
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    
    # OnePlus
    resetprop_if_diff ro.is_ever_orange 0
    resetprop_if_diff ro.boot.flash.locked 1
    
    # Secure boot
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.secureboot 1
    resetprop_if_diff vendor.boot.flash.locked 1
    
    # Knox (Samsung)
    resetprop_if_diff ro.boot.knox 0
    resetprop_if_diff ro.config.knox 0
    resetprop_if_diff ro.secureboot.devicelock 1
    
    log_msg "INFO" "Bootloader lock spoofing applied"
}

# Hide root-specific build properties
hide_build_properties() {
    log_msg "INFO" "Hiding build properties"
    
    # Build tags - should be release-keys
    for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.tags' || true); do
        resetprop_if_diff "$PROP" "release-keys"
    done
    
    # Build type - should be user
    for PROP in $(resetprop 2>/dev/null | grep -oE 'ro\..*\.build\.type' || true); do
        resetprop_if_diff "$PROP" "user"
    done
    
    # ADB
    resetprop_if_diff ro.adb.secure 1
    resetprop_if_diff ro.debuggable 0
    resetprop_if_diff ro.force.debuggable 0
    resetprop_if_diff ro.secure 1
    
    # Developer options indicators
    delprop_if_exist ro.build.selinux
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
    
    # Boot mode
    resetprop_if_match ro.boot.mode recovery unknown
    resetprop_if_match ro.bootmode recovery unknown
    resetprop_if_match vendor.boot.mode recovery unknown
    
    # SELinux
    resetprop_if_diff ro.boot.selinux enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0
    
    log_msg "INFO" "Build properties hidden"
}

# Hide Magisk-specific files and paths
hide_magisk_traces() {
    log_msg "INFO" "Hiding Magisk traces"
    
    # Check if we're in a targeted app context
    local found_target=false
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        # Skip comments and empty lines
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
        # Additional hiding when target app is running
        resetprop_if_diff persist.sys.adb.notify 0
        delprop_if_exist service.adb.tcp.port
    fi
}

# Process monitor - continuously monitor for target apps
monitor_target_apps() {
    local last_state=""
    
    while true; do
        if ! is_boot_completed; then
            sleep 5
            continue
        fi
        
        local current_state=""
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            case "$pkg" in
                ""|\#*) continue ;;
            esac
            if is_app_running "$pkg"; then
                current_state="${current_state}${pkg};"
            fi
        done < "$MODPATH/target_apps.txt"
        
        if [ "$current_state" != "$last_state" ]; then
            if [ -n "$current_state" ]; then
                log_msg "INFO" "Target apps detected: $current_state"
                spoof_bootloader_locked
                hide_build_properties
                hide_magisk_traces
            fi
            last_state="$current_state"
        fi
        
        sleep 3
    done
}

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

# Export all functions for use in other scripts
export -f log_msg 2>/dev/null || true
export -f resetprop_if_diff 2>/dev/null || true
export -f resetprop_if_match 2>/dev/null || true
export -f delprop_if_exist 2>/dev/null || true
export -f is_kernelsu 2>/dev/null || true
export -f is_magisk 2>/dev/null || true
export -f is_apatch 2>/dev/null || true
export -f detect_root_solution 2>/dev/null || true
export -f is_app_running 2>/dev/null || true
export -f is_boot_completed 2>/dev/null || true
export -f wait_for_boot 2>/dev/null || true
export -f spoof_bootloader_locked 2>/dev/null || true
export -f hide_build_properties 2>/dev/null || true
export -f hide_magisk_traces 2>/dev/null || true
export -f monitor_target_apps 2>/dev/null || true
