#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Keybox Updater Script
# Self-updating keybox fetcher with obfuscated source
# Author: lee-muriithi-kingori
# Version: v1.1.0
# ==========================================

MODPATH="${MODPATH:-/data/adb/modules/UBLESTRAMK}"
LOG_FILE="/data/local/tmp/UBLESTRAMK.log"
TEMP_DIR="/data/local/tmp"

# Obfuscated default source URL
# The URL is split and encoded to prevent easy extraction
# Each part is stored separately and combined at runtime
_SRC_PART1="aHR0cHM6Ly9yYXcuZ2l0"
_SRC_PART2="aHVidXNlcmNvbnRlbnQuY29t"
_SRC_PART3="L2xlZS1tdXJpaXRoaS1raW5nb3Jp"
_SRC_PART4="L2tleWJveC1zb3VyY2VzL21haW4"

# Decode helper (base64)
_b64decode() {
    echo "$1" | base64 -d 2>/dev/null
}

# Construct the default source URL from obfuscated parts
get_default_source_url() {
    local part1="$(_b64decode "$_SRC_PART1")"
    local part2="$(_b64decode "$_SRC_PART2")"
    local part3="$(_b64decode "$_SRC_PART3")"
    local part4="$(_b64decode "$_SRC_PART4")"
    echo "${part1}${part2}${part3}${part4}"
}

# Alternative source list (fallback chain)
# These are also obfuscated
get_fallback_sources() {
    local src1="$(_b64decode "aHR0cHM6Ly9naXRodWIuY29tL2xlZS1tdXJpaXRoaS1raW5nb3JpL2tleWJveC1zb3VyY2VzL3JlbGVhc2VzL2Rvd25sb2FkL2xhdGVzdC9rZXlib3gueG1s")"
    echo "$src1"
}

# Logging
log_msg() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] UBLESTRAMK-Keybox: $msg" >> "$LOG_FILE" 2>/dev/null
    log -t "UBLESTRAMK" "[$level] Keybox: $msg" 2>/dev/null
}

# Get current source type
get_source_type() {
    if [ -f "$MODPATH/.keybox_source_type" ]; then
        cat "$MODPATH/.keybox_source_type" 2>/dev/null
    else
        echo "default"
    fi
}

# Get custom URL
get_custom_url() {
    if [ -f "$MODPATH/.keybox_source_url" ]; then
        cat "$MODPATH/.keybox_source_url" 2>/dev/null
    else
        echo ""
    fi
}

# Get auto-update setting
get_auto_update() {
    if [ -f "$MODPATH/.keybox_auto_update" ]; then
        local val=$(cat "$MODPATH/.keybox_auto_update" 2>/dev/null)
        [ "$val" = "1" ]
    else
        return 0  # Default true
    fi
}

# Get update interval (hours)
get_update_interval() {
    if [ -f "$MODPATH/.keybox_update_interval" ]; then
        cat "$MODPATH/.keybox_update_interval" 2>/dev/null
    else
        echo "24"
    fi
}

# Check if we should update based on interval
should_update() {
    local last_update_file="$MODPATH/.keybox_last_update"
    local interval_hours=$(get_update_interval)
    local interval_seconds=$((interval_hours * 3600))
    
    if [ ! -f "$last_update_file" ]; then
        return 0  # Never updated, should update
    fi
    
    local last_update=$(cat "$last_update_file" 2>/dev/null)
    local current_time=$(date +%s)
    local elapsed=$((current_time - last_update))
    
    if [ "$elapsed" -ge "$interval_seconds" ]; then
        return 0  # Should update
    fi
    
    return 1  # Don't update yet
}

# Download keybox from URL
download_keybox() {
    local url="$1"
    local output="$2"
    
    log_msg "INFO" "Downloading keybox from source..."
    
    # Try different download methods
    if command -v curl >/dev/null 2>&1; then
        curl -sL --max-time 30 -o "$output" "$url" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=30 -O "$output" "$url" 2>/dev/null
    elif [ -f /system/bin/curl ]; then
        /system/bin/curl -sL --max-time 30 -o "$output" "$url" 2>/dev/null
    elif [ -f /system/bin/wget ]; then
        /system/bin/wget -q --timeout=30 -O "$output" "$url" 2>/dev/null
    else
        log_msg "ERROR" "No download tool available (curl/wget)"
        return 1
    fi
    
    # Verify download
    if [ -f "$output" ] && [ -s "$output" ]; then
        # Check if it's valid XML
        if head -1 "$output" | grep -q "xml\|XML"; then
            log_msg "INFO" "Keybox downloaded successfully"
            return 0
        else
            log_msg "WARN" "Downloaded file doesn't appear to be valid XML"
            return 1
        fi
    fi
    
    log_msg "ERROR" "Failed to download keybox"
    return 1
}

# Validate keybox XML
validate_keybox() {
    local file="$1"
    
    # Check file exists and is readable
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        log_msg "ERROR" "Keybox file not found or not readable"
        return 1
    fi
    
    # Check file size (should be reasonable)
    local size=$(stat -c%s "$file" 2>/dev/null)
    if [ "$size" -lt 100 ]; then
        log_msg "ERROR" "Keybox file too small ($size bytes)"
        return 1
    fi
    
    # Check for required XML structure
    if ! grep -q "<Keybox>" "$file" 2>/dev/null; then
        log_msg "ERROR" "Invalid keybox XML structure (no <Keybox> tag)"
        return 1
    fi
    
    # Check for keys
    if ! grep -q "<Key " "$file" 2>/dev/null; then
        log_msg "ERROR" "Invalid keybox XML (no <Key> elements)"
        return 1
    fi
    
    # Check for certificate chain
    if ! grep -q "<Certificate" "$file" 2>/dev/null; then
        log_msg "WARN" "Keybox has no certificate chain"
    fi
    
    return 0
}

# Backup current keybox
backup_keybox() {
    if [ -f "$MODPATH/keybox.xml" ]; then
        local backup_name="keybox.xml.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$MODPATH/keybox.xml" "$MODPATH/$backup_name"
        log_msg "INFO" "Backed up current keybox to $backup_name"
    fi
}

# Install new keybox
install_keybox() {
    local source_file="$1"
    
    backup_keybox
    
    cp "$source_file" "$MODPATH/keybox.xml"
    chmod 644 "$MODPATH/keybox.xml"
    chown root:root "$MODPATH/keybox.xml"
    
    # Update timestamp
    date +%s > "$MODPATH/.keybox_last_update"
    
    log_msg "INFO" "New keybox installed successfully"
    return 0
}

# Update from default source
update_from_default() {
    log_msg "INFO" "Fetching from built-in source..."
    
    local default_url=$(get_default_source_url)
    local temp_file="$TEMP_DIR/keybox_new.xml"
    
    # Remove old temp file
    rm -f "$temp_file"
    
    # Try primary source
    if download_keybox "$default_url" "$temp_file"; then
        if validate_keybox "$temp_file"; then
            install_keybox "$temp_file"
            rm -f "$temp_file"
            return 0
        fi
    fi
    
    # Try fallback sources
    log_msg "INFO" "Trying fallback sources..."
    local fallback1=$(get_fallback_sources)
    
    if [ -n "$fallback1" ]; then
        rm -f "$temp_file"
        if download_keybox "$fallback1" "$temp_file"; then
            if validate_keybox "$temp_file"; then
                install_keybox "$temp_file"
                rm -f "$temp_file"
                return 0
            fi
        fi
    fi
    
    rm -f "$temp_file"
    log_msg "ERROR" "All default sources failed"
    return 1
}

# Update from custom URL
update_from_custom_url() {
    local url=$(get_custom_url)
    
    if [ -z "$url" ]; then
        log_msg "ERROR" "No custom URL configured"
        return 1
    fi
    
    log_msg "INFO" "Fetching from custom URL..."
    
    local temp_file="$TEMP_DIR/keybox_new.xml"
    rm -f "$temp_file"
    
    if download_keybox "$url" "$temp_file"; then
        if validate_keybox "$temp_file"; then
            install_keybox "$temp_file"
            rm -f "$temp_file"
            return 0
        fi
    fi
    
    rm -f "$temp_file"
    log_msg "ERROR" "Custom URL fetch failed"
    return 1
}

# Update from local file
update_from_local() {
    log_msg "INFO" "Using local keybox.xml"
    
    if [ -f "$MODPATH/keybox.xml" ]; then
        if validate_keybox "$MODPATH/keybox.xml"; then
            log_msg "INFO" "Local keybox is valid"
            date +%s > "$MODPATH/.keybox_last_update"
            return 0
        else
            log_msg "ERROR" "Local keybox is invalid"
            return 1
        fi
    else
        log_msg "ERROR" "No local keybox.xml found"
        return 1
    fi
}

# Main update function
perform_update() {
    local source_type=$(get_source_type)
    local result=1
    
    log_msg "INFO" "Starting keybox update (source: $source_type)"
    
    case "$source_type" in
        default)
            update_from_default
            result=$?
            ;;
        custom_url)
            update_from_custom_url
            result=$?
            ;;
        local_file)
            update_from_local
            result=$?
            ;;
        *)
            log_msg "WARN" "Unknown source type: $source_type, using default"
            update_from_default
            result=$?
            ;;
    esac
    
    if [ "$result" -eq 0 ]; then
        log_msg "INFO" "Keybox update completed successfully"
    else
        log_msg "WARN" "Keybox update failed"
    fi
    
    return $result
}

# Periodic update checker (called by service.sh)
periodic_check() {
    # Only check if auto-update is enabled
    if ! get_auto_update; then
        return 0
    fi
    
    # Check if it's time to update
    if should_update; then
        perform_update
    fi
}

# Main entry point
case "${1:-}" in
    --force)
        # Force update regardless of schedule
        log_msg "INFO" "Force update triggered"
        perform_update
        exit $?
        ;;
    --check)
        # Periodic check (called by service)
        periodic_check
        exit $?
        ;;
    --validate)
        # Validate current keybox
        if [ -f "$MODPATH/keybox.xml" ]; then
            if validate_keybox "$MODPATH/keybox.xml"; then
                echo "Valid"
                exit 0
            else
                echo "Invalid"
                exit 1
            fi
        else
            echo "Not found"
            exit 1
        fi
        ;;
    --source)
        # Show current source (for debugging)
        echo "Type: $(get_source_type)"
        echo "URL: $(get_custom_url)"
        echo "Auto-update: $(get_auto_update && echo 'enabled' || echo 'disabled')"
        echo "Interval: $(get_update_interval) hours"
        exit 0
        ;;
    *)
        # Default: perform update check
        perform_update
        exit $?
        ;;
esac
