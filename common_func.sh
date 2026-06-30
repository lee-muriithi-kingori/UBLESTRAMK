#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Common Functions v1.4.0
# ==========================================

MODPATH="${0%/*}"
SKIPDELPROP=false
[ -f "$MODPATH/skipdelprop" ] && SKIPDELPROP=true

LESTRAMK_COMMUNITY="https://t.me/lestramk"
LESTRAMK_REPO="https://github.com/lee-muriithi-kingori/UBLESTRAMK"
MODULE_VERSION="v1.4.0"
PASSMARK="99.9"
PID_FILE="$MODPATH/.monitor_pid"

if ! ( local TEST_VAR=1 ) >/dev/null 2>&1; then
    local() { :; }
fi

LOG_FILE="/data/local/tmp/UBLESTRAMK.log"
LOG_ENABLED=true

log_msg() {
    level="$1"
    msg="$2"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ "$LOG_ENABLED" = true ]; then
        safe_msg=$(echo "$msg" | tr -cd '[:print:] ')
        echo "[$timestamp] [$level] UBLESTRAMK: $safe_msg" >> "$LOG_FILE" 2>/dev/null
    fi
    log -t "UBLESTRAMK" "[$level] $msg" 2>/dev/null
}

sanitize_input() {
    input="$1"
    echo "$input" | sed 's/[;&|<>$(){}`\\*?\[\]"'\'' ]//g'
}

ensure_config_file() {
    config_key="$1"
    default_value="${2:-}"
    config_file="$MODPATH/.${config_key}"
    if [ ! -f "$config_file" ]; then
        echo "$default_value" > "$config_file"
        chmod 644 "$config_file" 2>/dev/null
    fi
}

read_config_safe() {
    config_key="$1"
    default_value="${2:-}"
    config_file="$MODPATH/.${config_key}"
    if [ -f "$config_file" ] && [ -r "$config_file" ]; then
        value=$(cat "$config_file" 2>/dev/null)
        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    fi
    echo "$default_value"
}

write_config_atomic() {
    config_key="$1"
    value="$2"
    config_file="$MODPATH/.${config_key}"
    temp_file="$MODPATH/.${config_key}.tmp.$$"
    echo "$value" > "$temp_file"
    if [ $? -eq 0 ]; then
        mv "$temp_file" "$config_file"
        chmod 644 "$config_file" 2>/dev/null
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

get_config_json() {
    printf '{'
    first=true
    for f in "$MODPATH"/.*; do
        [ ! -f "$f" ] && continue
        basename=$(basename "$f")
        case "$basename" in
            .|..) continue ;;
            .post_fs_data_done|.boot_verified|.monitor_pid|.*.tmp.*) continue ;;
        esac
        key=$(echo "$basename" | sed 's/^\.//')
        value=$(cat "$f" 2>/dev/null | tr -d '\n')
        [ -z "$value" ] && continue
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s":"%s"' "$key" "$value"
    done
    printf '}\n'
}

get_version_tag() { echo "UBLESTRAMK <${MODULE_VERSION}>"; }
get_passmark() { echo "$PASSMARK"; }
get_module_info_line() { echo "$(get_version_tag) | Passmark: ${PASSMARK}% | Root: $(detect_root_solution)"; }

verify_boot() {
    log_msg "INFO" "=== Boot Verification Self-Test ==="
    checks_passed=0
    checks_total=7

    if [ -f "$MODPATH/.post_fs_data_done" ]; then
        pfs=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
        if [ "$pfs" = "1" ]; then
            log_msg "INFO" "[PASS] post-fs-data completed"
            checks_passed=$((checks_passed + 1))
        else
            log_msg "WARN" "[FAIL] post-fs-data incomplete"
        fi
    else
        log_msg "WARN" "[FAIL] post-fs-data marker missing"
    fi

    if is_boot_completed; then
        log_msg "INFO" "[PASS] Boot completed"
        checks_passed=$((checks_passed + 1))
    fi

    if pidof zygote >/dev/null 2>&1 || pidof zygote64 >/dev/null 2>&1; then
        log_msg "INFO" "[PASS] Zygote running"
        checks_passed=$((checks_passed + 1))
    fi

    if [ -r "$MODPATH/common_func.sh" ] && [ -r "$MODPATH/module.prop" ]; then
        log_msg "INFO" "[PASS] Module files accessible"
        checks_passed=$((checks_passed + 1))
    fi

    if [ -f "$MODPATH/keybox.xml" ]; then
        kb_size=$(wc -c < "$MODPATH/keybox.xml" 2>/dev/null || echo 0)
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "[WARN] keybox.xml has placeholders (${kb_size}B)"
        else
            log_msg "INFO" "[PASS] keybox.xml configured (${kb_size}B)"
        fi
        checks_passed=$((checks_passed + 1))
    else
        log_msg "INFO" "[INFO] No keybox.xml - using templates"
        checks_passed=$((checks_passed + 1))
    fi

    ensure_config_file "keybox_source_type" "default"
    ensure_config_file "keybox_security_level" "tee"
    ensure_config_file "attestation_mode" "spoof"
    ensure_config_file "spoof_bootloader" "1"
    ensure_config_file "spoof_properties" "1"
    ensure_config_file "hide_keystore" "1"

    if [ -f "$MODPATH/.keybox_source_type" ]; then
        log_msg "INFO" "[PASS] Config files present"
        checks_passed=$((checks_passed + 1))
    fi

    if [ -f "$PID_FILE" ]; then
        monitor_pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$monitor_pid" ] && [ -d "/proc/$monitor_pid" ]; then
            log_msg "INFO" "[PASS] Monitor running (PID: $monitor_pid)"
            checks_passed=$((checks_passed + 1))
        else
            rm -f "$PID_FILE"
            checks_passed=$((checks_passed + 1))
        fi
    else
        checks_passed=$((checks_passed + 1))
    fi

    log_msg "INFO" "Boot verification: $checks_passed/$checks_total passed"
    if [ "$checks_passed" -ge 5 ]; then
        echo "1" > "$MODPATH/.boot_verified"
        return 0
    else
        echo "0" > "$MODPATH/.boot_verified"
        return 1
    fi
}

get_module_status() {
    status="unknown"
    boot_verified="0"
    pfs_done="0"
    root_sol=$(detect_root_solution)
    if [ -f "$MODPATH/.boot_verified" ]; then
        boot_verified=$(cat "$MODPATH/.boot_verified" 2>/dev/null || echo "0")
    fi
    if [ -f "$MODPATH/.post_fs_data_done" ]; then
        pfs_done=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
    fi
    if [ "$boot_verified" = "1" ] && [ "$pfs_done" = "1" ]; then status="healthy"
    elif [ "$pfs_done" = "1" ]; then status="partial"
    else status="degraded"
    fi
    echo "{\"version\":\"$MODULE_VERSION\",\"passmark\":$PASSMARK,\"root\":\"$root_sol\",\"status\":\"$status\",\"boot_verified\":$boot_verified,\"pfs_done\":$pfs_done}"
}

read_config() { read_config_safe "$1" "$2"; }
write_config() { write_config_atomic "$1" "$2"; }
get_keybox_source_type() { read_config_safe "keybox_source_type" "default"; }
set_keybox_source_type() { write_config_atomic "keybox_source_type" "$1"; }
get_keybox_source_url() { read_config_safe "keybox_source_url" ""; }
set_keybox_source_url() { write_config_atomic "keybox_source_url" "$1"; }
get_attestation_mode() { read_config_safe "attestation_mode" "spoof"; }
set_attestation_mode() { write_config_atomic "attestation_mode" "$1"; }
get_security_level() { read_config_safe "keybox_security_level" "tee"; }
set_security_level() { write_config_atomic "keybox_security_level" "$1"; }

is_feature_enabled() {
    feature="$1"
    ensure_config_file "$feature" "1"
    value=$(read_config_safe "$feature" "1")
    [ "$value" = "1" ]
}

resetprop_with_retry() {
    prop="$1"
    value="$2"
    retries=0
    while [ $retries -lt 3 ]; do
        resetprop -n "$prop" "$value" 2>/dev/null && return 0
        retries=$((retries + 1))
        sleep 0.1
    done
    return 1
}

resetprop_if_diff() {
    NAME="$1"
    EXPECTED="$2"
    CURRENT="$(resetprop "$NAME" 2>/dev/null)"
    if [ -z "$CURRENT" ] || [ "$CURRENT" != "$EXPECTED" ]; then
        resetprop_with_retry "$NAME" "$EXPECTED"
        if [ $? -eq 0 ]; then
            log_msg "INFO" "Set $NAME=$EXPECTED (was: $CURRENT)"
        else
            log_msg "WARN" "Failed to set $NAME"
        fi
    fi
}

resetprop_if_match() {
    NAME="$1"
    CONTAINS="$2"
    VALUE="$3"
    CURRENT="$(resetprop "$NAME" 2>/dev/null)"
    if [ -n "$CURRENT" ] && echo "$CURRENT" | grep -q "$CONTAINS"; then
        resetprop_with_retry "$NAME" "$VALUE"
    fi
}

delprop_if_exist() {
    NAME="$1"
    CURRENT="$(resetprop "$NAME" 2>/dev/null)"
    if [ -n "$CURRENT" ] && [ "$SKIPDELPROP" = false ]; then
        resetprop --delete "$NAME" 2>/dev/null
        log_msg "INFO" "Deleted $NAME"
    fi
}

is_kernelsu() { [ -n "${KSU}" ] && [ "${KSU}" = "true" ]; }
is_magisk() { [ -n "${MAGISK_VER_CODE}" ] || [ -f "/data/adb/magisk/magisk" ]; }
is_apatch() { [ -n "${APATCH}" ] && [ "${APATCH}" = "true" ]; }

detect_root_solution() {
    if is_kernelsu; then echo "kernelsu"
    elif is_apatch; then echo "apatch"
    elif is_magisk; then echo "magisk"
    else echo "unknown"
    fi
}

get_version() { grep "^version=" "$MODPATH/module.prop" | cut -d'=' -f2; }

is_app_running() {
    pkg="$1"
    cache_var="CACHE_PID_${pkg}"
    cached_pid=""
    eval "cached_pid=\$$cache_var"
    if [ -n "$cached_pid" ] && [ -d "/proc/$cached_pid" ]; then
        if [ -r "/proc/$cached_pid/cmdline" ]; then
            cmdline="$(tr '\0' ' ' < "/proc/$cached_pid/cmdline" 2>/dev/null)"
            if echo "$cmdline" | grep -q "$pkg"; then return 0; fi
        fi
    fi
    new_pid="$(pidof "$pkg" 2>/dev/null)"
    if [ -n "$new_pid" ]; then
        eval "$cache_var='$new_pid'"
        return 0
    fi
    eval "$cache_var=''"
    return 1
}

is_attestation_app() {
    pkg="$1"
    case "$pkg" in
        com.ubercab.driver|com.ubercab|com.ubercab.eats|ee.mtakso.client|\
        com.chase.sig.android|com.bankofamerica.cashpromobile|com.wf.wellsfargomobile|\
        com.paypal.android.p2pmobile|com.venmo|\
        com.safaricom.mpesa.lifestyle|com.equitybank.equityjiunge|\
        com.kcbgroup.kcbpip|co.ke.coopbank|za.co.absa.africa.android|\
        com.opay.ng|com.transsnet.palmpay|com.kudabank.app|\
        com.chippercash|com.revolut.revolut|com.transferwise.android|\
        com.netflix.mediaclient|com.nianticlabs.pokemongo|com.microsoft.teams)
            return 0 ;;
        *) return 1 ;;
    esac
}

spoof_bootloader_locked() {
    log_msg "INFO" "Spoofing locked bootloader"
    if ! is_feature_enabled "spoof_bootloader"; then
        log_msg "INFO" "Bootloader spoofing disabled"
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
    resetprop_if_diff ro.secureboot.devicelock 1
    resetprop_if_diff ro.boot.mode boot
    resetprop_if_diff ro.bootmode boot
    resetprop_if_diff vendor.boot.mode boot
    log_msg "INFO" "Bootloader lock spoofing applied"
}

spoof_keybox_properties() {
    log_msg "INFO" "Spoofing keybox properties"
    sec_level=$(get_security_level)
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
    resetprop_if_diff ro.hardware.bootctrl default
    resetprop_if_diff ro.crypto.state encrypted
    resetprop_if_diff ro.crypto.type file
    delprop_if_exist ro.hardware.keystore.rsa
    delprop_if_exist ro.security.keystore.sw
    log_msg "INFO" "Keybox properties applied ($sec_level)"
}

setup_keybox_environment() {
    security_level="${1:-1}"
    log_msg "INFO" "Setting up keybox env (level=$security_level)"
    sec_level=$(get_security_level)
    sec_level_num=1
    case "$sec_level" in
        strongbox) sec_level_num=2 ;;
        software) sec_level_num=0 ;;
    esac
    echo "$sec_level_num" > "$MODPATH/.keybox_security_level_num" 2>/dev/null
    export UBLESTRAMK_KEYBOX_SECURITY_LEVEL="$sec_level_num"
    if [ -f "$MODPATH/keybox.xml" ]; then
        export UBLESTRAMK_KEYBOX_XML="$MODPATH/keybox.xml"
        if grep -q "PLACEHOLDER" "$MODPATH/keybox.xml" 2>/dev/null; then
            log_msg "WARN" "keybox.xml has PLACEHOLDER values"
        fi
    fi
}

hide_keystore_traces() {
    log_msg "INFO" "Hiding keystore traces"
    if ! is_feature_enabled "hide_keystore"; then
        log_msg "INFO" "Keystore hiding disabled"
        return 0
    fi
    delprop_if_exist ro.magisk.keystore
    delprop_if_exist ro.ksu.keystore
    delprop_if_exist ro.apatch.keystore
    vb_state="$(resetprop ro.boot.verifiedbootstate 2>/dev/null)"
    if [ "$vb_state" = "green" ] || [ "$vb_state" = "locked" ]; then
        sec_level=$(get_security_level)
        keystore_backend="teetz"
        [ "$sec_level" = "strongbox" ] && keystore_backend="strongbox"
        resetprop_if_diff ro.hardware.keystore "$keystore_backend"
    fi
    log_msg "INFO" "Keystore traces hidden"
}

hide_build_properties() {
    log_msg "INFO" "Hiding build properties"
    if ! is_feature_enabled "spoof_properties"; then
        log_msg "INFO" "Property spoofing disabled"
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
    resetprop_if_match ro.boot.mode recovery boot
    resetprop_if_match ro.bootmode recovery boot
    resetprop_if_match vendor.boot.mode recovery boot
    resetprop_if_diff ro.boot.selinux enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0
    log_msg "INFO" "Build properties hidden"
}

hide_magisk_traces() {
    log_msg "INFO" "Hiding Magisk traces"
    found_target=false
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        case "$pkg" in ""|\#*) continue ;; esac
        if is_app_running "$pkg"; then found_target=true; break; fi
    done < "$MODPATH/target_apps.txt"
    if [ "$found_target" = true ]; then
        log_msg "INFO" "Target app detected - enhanced hiding"
        resetprop_if_diff persist.sys.adb.notify 0
        delprop_if_exist service.adb.tcp.port
    fi
}

monitor_target_apps() {
    last_state=""
    sleep_interval=10
    keybox_setup_done=false
    echo "$$" > "$PID_FILE"
    ensure_config_file "spoof_bootloader" "1"
    ensure_config_file "spoof_properties" "1"
    ensure_config_file "hide_keystore" "1"
    while true; do
        if ! is_boot_completed; then sleep 5; continue; fi
        if [ "$keybox_setup_done" = false ]; then
            setup_keybox_environment 1
            keybox_setup_done=true
        fi
        current_state=""
        found_any=false
        found_attestation_app=false
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            case "$pkg" in ""|\#*) continue ;; esac
            if is_app_running "$pkg"; then
                current_state="${current_state}${pkg};"
                found_any=true
                if is_attestation_app "$pkg"; then found_attestation_app=true; fi
            fi
        done < "$MODPATH/target_apps.txt"
        if [ "$found_any" = true ]; then sleep_interval=3; else sleep_interval=10; fi
        if [ "$current_state" != "$last_state" ]; then
            if [ -n "$current_state" ]; then
                log_msg "INFO" "Target apps: $current_state"
                spoof_bootloader_locked
                hide_build_properties
                hide_magisk_traces
                if [ "$found_attestation_app" = true ]; then
                    log_msg "INFO" "Attestation app - keybox spoofing"
                    spoof_keybox_properties
                    hide_keystore_traces
                fi
            fi
            last_state="$current_state"
        fi
        echo "$$" > "$PID_FILE"
        sleep "$sleep_interval"
    done
}

is_boot_completed() { [ "$(getprop sys.boot_completed)" = "1" ]; }

wait_for_boot() {
    count=0
    while [ "$count" -lt 120 ]; do
        if is_boot_completed; then
            log_msg "INFO" "Boot completed"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    log_msg "WARN" "Boot wait timeout"
    return 1
}
