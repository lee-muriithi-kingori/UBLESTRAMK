#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Keybox Updater Script v1.4.0
# ==========================================

MODPATH="${MODPATH:-/data/adb/modules/UBLESTRAMK}"
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"
TEMP_DIR="/data/local/tmp"
LOCK_FILE="$TEMP_DIR/ublestramk_keybox.lock"
TEMP_KEYBOX="$TEMP_DIR/keybox_new_$$.xml"

cleanup() {
    rm -f "$TEMP_KEYBOX" "$TEMP_KEYBOX.sha256"
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT HUP INT TERM

_SRC_PART1="aHR0cHM6Ly9yYXcuZ2l0"
_SRC_PART2="aHVidXNlcmNvbnRlbnQuY29t"
_SRC_PART3="L2xlZS1tdXJpaXRoaS1raW5nb3Jp"
_SRC_PART4="L2tleWJveC1zb3VyY2VzL21haW4"

_b64decode() {
    input="$1"
    if echo "$input" | base64 -d >/dev/null 2>&1; then
        echo "$input" | base64 -d
    elif echo "$input" | busybox base64 -d >/dev/null 2>&1; then
        echo "$input" | busybox base64 -d
    elif echo "$input" | openssl enc -base64 -d >/dev/null 2>&1; then
        echo "$input" | openssl enc -base64 -d
    else
        echo ""
    fi
}

get_default_source_url() {
    part1="$(_b64decode "$_SRC_PART1")"
    part2="$(_b64decode "$_SRC_PART2")"
    part3="$(_b64decode "$_SRC_PART3")"
    part4="$(_b64decode "$_SRC_PART4")"
    echo "${part1}${part2}${part3}${part4}"
}

get_fallback_sources() {
    src1="$(_b64decode "aHR0cHM6Ly9naXRodWIuY29tL2xlZS1tdXJpaXRoaS1raW5nb3JpL2tleWJveC1zb3VyY2VzL3JlbGVhc2VzL2Rvd25sb2FkL2xhdGVzdC9rZXlib3gueG1s")"
    echo "$src1"
}

log_msg() {
    level="$1"
    msg="$2"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    safe_msg=$(echo "$msg" | tr -cd '[:print:] ')
    echo "[$timestamp] [$level] UBLESTRAMK-Keybox: $safe_msg" >> "$LOG_FILE" 2>/dev/null
    log -t "UBLESTRAMK" "[$level] Keybox: $msg" 2>/dev/null
}

acquire_lock() {
    attempt=0
    while [ $attempt -lt 30 ]; do
        if mkdir "$LOCK_FILE" 2>/dev/null; then return 0; fi
        attempt=$((attempt + 1))
        sleep 1
    done
    log_msg "WARN" "Could not acquire lock"
    return 1
}

release_lock() { rm -rf "$LOCK_FILE" 2>/dev/null; }

get_source_type() {
    if [ -f "$MODPATH/.keybox_source_type" ]; then
        cat "$MODPATH/.keybox_source_type" 2>/dev/null
    else echo "default"; fi
}

get_custom_url() {
    if [ -f "$MODPATH/.keybox_source_url" ]; then
        cat "$MODPATH/.keybox_source_url" 2>/dev/null
    else echo ""; fi
}

get_auto_update() {
    if [ -f "$MODPATH/.keybox_auto_update" ]; then
        val=$(cat "$MODPATH/.keybox_auto_update" 2>/dev/null)
        [ "$val" = "1" ]
    else return 0; fi
}

get_update_interval() {
    if [ -f "$MODPATH/.keybox_update_interval" ]; then
        cat "$MODPATH/.keybox_update_interval" 2>/dev/null
    else echo "24"; fi
}

has_network() {
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then return 0; fi
    if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then return 0; fi
    return 1
}

download_keybox() {
    url="$1"
    output="$2"
    log_msg "INFO" "Downloading keybox..."
    if ! has_network; then
        log_msg "WARN" "No network"
        return 1
    fi
    download_tool=""
    if command -v curl >/dev/null 2>&1; then
        download_tool="curl -sL --max-time 30 --retry 2"
    elif command -v wget >/dev/null 2>&1; then
        download_tool="wget -q --timeout=30 -O"
    elif [ -f /system/bin/curl ]; then
        download_tool="/system/bin/curl -sL --max-time 30 --retry 2"
    elif [ -f /system/bin/wget ]; then
        download_tool="/system/bin/wget -q --timeout=30 -O"
    elif command -v busybox >/dev/null 2>&1 && busybox wget --help >/dev/null 2>&1; then
        download_tool="busybox wget -q -O"
    else
        log_msg "ERROR" "No download tool"
        return 1
    fi
    attempt=0
    max_attempts=3
    while [ $attempt -lt $max_attempts ]; do
        rm -f "$output"
        if echo "$download_tool" | grep -q 'wget.*-O'; then
            $download_tool "$output" "$url" 2>/dev/null
        else
            $download_tool -o "$output" "$url" 2>/dev/null
        fi
        if [ -f "$output" ]; then
            file_size=$(wc -c < "$output" 2>/dev/null || echo 0)
            if [ "$file_size" -gt 100 ]; then
                log_msg "INFO" "Downloaded $file_size bytes"
                return 0
            fi
        fi
        attempt=$((attempt + 1))
        if [ $attempt -lt $max_attempts ]; then
            backoff=$((2 ** attempt))
            log_msg "INFO" "Retry $attempt in ${backoff}s"
            sleep $backoff
        fi
    done
    log_msg "ERROR" "Download failed"
    return 1
}

validate_keybox() {
    file="$1"
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        log_msg "ERROR" "Keybox not found"
        return 1
    fi
    size=$(wc -c < "$file" 2>/dev/null || echo 0)
    if [ "$size" -lt 100 ]; then
        log_msg "ERROR" "Keybox too small ($size bytes)"
        return 1
    fi
    if [ "$size" -gt 1048576 ]; then
        log_msg "ERROR" "Keybox too large ($size bytes)"
        return 1
    fi
    if ! grep -q "<?xml" "$file" 2>/dev/null; then
        log_msg "ERROR" "Not valid XML"
        return 1
    fi
    if ! grep -qi "<Keybox" "$file" 2>/dev/null; then
        log_msg "ERROR" "No <Keybox> tag"
        return 1
    fi
    if ! grep -qi "<Key" "$file" 2>/dev/null; then
        log_msg "ERROR" "No <Key> elements"
        return 1
    fi
    cert_count=$(grep -ci "<Certificate" "$file" 2>/dev/null || echo 0)
    log_msg "INFO" "Found $cert_count certs"
    if grep -qi "PLACEHOLDER" "$file" 2>/dev/null; then
        log_msg "WARN" "Keybox has PLACEHOLDER values"
    fi
    return 0
}

backup_keybox() {
    if [ -f "$MODPATH/keybox.xml" ]; then
        backup_name="keybox.xml.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$MODPATH/keybox.xml" "$MODPATH/$backup_name"
        log_msg "INFO" "Backed up to $backup_name"
        for old_backup in $(ls -t "$MODPATH"/keybox.xml.bak.* 2>/dev/null | tail -n +6); do
            rm -f "$old_backup"
        done
    fi
}

install_keybox() {
    source_file="$1"
    backup_keybox
    cp "$source_file" "$MODPATH/keybox.xml"
    chmod 644 "$MODPATH/keybox.xml"
    chown root:root "$MODPATH/keybox.xml" 2>/dev/null
    date +%s > "$MODPATH/.keybox_last_update"
    log_msg "INFO" "Keybox installed"
}

update_from_default() {
    log_msg "INFO" "Fetching from built-in source..."
    default_url=$(get_default_source_url)
    if [ -z "$default_url" ]; then
        log_msg "ERROR" "Could not decode URL"
        return 1
    fi
    if download_keybox "$default_url" "$TEMP_KEYBOX"; then
        if validate_keybox "$TEMP_KEYBOX"; then
            install_keybox "$TEMP_KEYBOX"
            return $?
        fi
    fi
    fallback1=$(get_fallback_sources)
    if [ -n "$fallback1" ]; then
        if download_keybox "$fallback1" "$TEMP_KEYBOX"; then
            if validate_keybox "$TEMP_KEYBOX"; then
                install_keybox "$TEMP_KEYBOX"
                return $?
            fi
        fi
    fi
    log_msg "ERROR" "All sources failed"
    return 1
}

update_from_custom_url() {
    url=$(get_custom_url)
    if [ -z "$url" ]; then
        log_msg "ERROR" "No custom URL"
        return 1
    fi
    case "$url" in
        http://*|https://*) ;;
        *) log_msg "ERROR" "Invalid URL"; return 1 ;;
    esac
    log_msg "INFO" "Fetching from custom URL..."
    if download_keybox "$url" "$TEMP_KEYBOX"; then
        if validate_keybox "$TEMP_KEYBOX"; then
            install_keybox "$TEMP_KEYBOX"
            return $?
        fi
    fi
    log_msg "ERROR" "Custom URL failed"
    return 1
}

update_from_local() {
    log_msg "INFO" "Using local keybox.xml"
    if [ -f "$MODPATH/keybox.xml" ]; then
        if validate_keybox "$MODPATH/keybox.xml"; then
            log_msg "INFO" "Local keybox valid"
            date +%s > "$MODPATH/.keybox_last_update"
            return 0
        else
            log_msg "ERROR" "Local keybox invalid"
            return 1
        fi
    else
        log_msg "ERROR" "No local keybox.xml"
        return 1
    fi
}

perform_update() {
    source_type=$(get_source_type)
    result=1
    log_msg "INFO" "Keybox update (source: $source_type)"
    if ! acquire_lock; then return 1; fi
    case "$source_type" in
        default) update_from_default; result=$? ;;
        custom_url) update_from_custom_url; result=$? ;;
        local_file) update_from_local; result=$? ;;
        *) log_msg "WARN" "Unknown source: $source_type"; update_from_default; result=$? ;;
    esac
    release_lock
    return $result
}

should_update() {
    last_update_file="$MODPATH/.keybox_last_update"
    interval_hours=$(get_update_interval)
    interval_seconds=$((interval_hours * 3600))
    if [ ! -f "$last_update_file" ]; then return 0; fi
    last_update=$(cat "$last_update_file" 2>/dev/null || echo 0)
    current_time=$(date +%s)
    elapsed=$((current_time - last_update))
    if [ "$elapsed" -ge "$interval_seconds" ]; then return 0; fi
    return 1
}

periodic_check() {
    if ! get_auto_update; then return 0; fi
    if should_update; then perform_update; fi
}

case "${1:-}" in
    --force) log_msg "INFO" "Force update"; perform_update; exit $? ;;
    --check) periodic_check; exit $? ;;
    --validate)
        if [ -f "$MODPATH/keybox.xml" ]; then
            if validate_keybox "$MODPATH/keybox.xml"; then echo "Valid"; exit 0;
            else echo "Invalid"; exit 1; fi
        else echo "Not found"; exit 1; fi ;;
    --source)
        echo "Type: $(get_source_type)"
        echo "URL: $(get_custom_url)"
        echo "Auto-update: $(get_auto_update && echo 'enabled' || echo 'disabled')"
        echo "Interval: $(get_update_interval)h"
        exit 0 ;;
    *) perform_update; exit $? ;;
esac
