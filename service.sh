#!/system/bin/sh
# UBLESTRAMK Service Script v1.4.0
MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"

BOOT_START_TIME=$(date +%s 2>/dev/null || echo 0)
PID_FILE="$MODPATH/.monitor_pid"

log_msg "INFO" "=== UBLESTRAMK service v1.4.0 ==="
log_msg "INFO" "$(get_module_info_line)"

if [ -f "$MODPATH/.post_fs_data_done" ]; then
    PFS=$(cat "$MODPATH/.post_fs_data_done" 2>/dev/null || echo "0")
    [ "$PFS" = "1" ] && log_msg "INFO" "post-fs-data OK" || log_msg "WARN" "post-fs-data incomplete"
else
    echo "0" > "$MODPATH/.post_fs_data_done" 2>/dev/null || true
fi

if [ -f "$MODPATH/.safe_mode_detected" ]; then
    log_msg "INFO" "Safe mode - minimal service"
    sleep 30; exit 0
fi

ensure_config_file() { [ ! -f "$MODPATH/.${1}" ] && echo "${2}" > "$MODPATH/.${1}" && chmod 644 "$MODPATH/.${1}"; }
ensure_config_file "keybox_source_type" "default"
ensure_config_file "keybox_auto_update" "1"
ensure_config_file "keybox_update_interval" "24"
ensure_config_file "attestation_mode" "spoof"
ensure_config_file "keybox_security_level" "tee"
ensure_config_file "spoof_bootloader" "1"
ensure_config_file "spoof_properties" "1"
ensure_config_file "hide_keystore" "1"
ensure_config_file "keybox_source_url" ""

if [ -f "$MODPATH/update_service_addon.sh" ]; then
    . "$MODPATH/update_service_addon.sh"
    ensure_webui_config
fi

spoof_bootloader_locked
hide_build_properties

( sleep 10
  resetprop_if_diff ro.secureboot.lockstate locked
  resetprop_if_diff ro.boot.flash.locked 1
  resetprop_if_diff ro.boot.verifiedbootstate green
  resetprop_if_diff vendor.boot.verifiedbootstate green
  resetprop_if_diff ro.boot.veritymode enforcing
  resetprop_if_diff vendor.boot.vbmeta.device_state locked
  resetprop_if_diff sys.oem_unlock_allowed 0
  if [ "$SKIPDELPROP" = false ]; then delprop_if_exist ro.build.selinux; fi
  if is_boot_completed; then
      echo "1" > "$MODPATH/.boot_verified" 2>/dev/null || true
  fi
) &

if [ -f "$MODPATH/keybox_updater.sh" ]; then
    ( NETWORK_WAIT=0
      while [ "$NETWORK_WAIT" -lt 60 ]; do
          if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then break; fi
          sleep 5; NETWORK_WAIT=$((NETWORK_WAIT + 5))
      done
      [ "$NETWORK_WAIT" -lt 60 ] && sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1
    ) &
fi

wait_for_boot
log_msg "INFO" "Starting monitor"
is_boot_completed && verify_boot || log_msg "WARN" "Boot timeout"

start_monitor() {
    rm -f "$PID_FILE"
    ( nohup sh -c '
        MODPATH="'"$MODPATH"'"
        . "$MODPATH/common_func.sh"
        if [ -f "$MODPATH/update_service_addon.sh" ]; then . "$MODPATH/update_service_addon.sh"; fi
        echo "$$" > "$MODPATH/.monitor_pid"
        for cfg in spoof_bootloader:1 spoof_properties:1 hide_keystore:1 keybox_source_type:default keybox_security_level:tee attestation_mode:spoof; do
            k=$(echo "$cfg" | cut -d: -f1); v=$(echo "$cfg" | cut -d: -f2)
            [ ! -f "$MODPATH/.${k}" ] && echo "$v" > "$MODPATH/.${k}"
        done
        last_state=""; sleep_interval=10; keybox_setup_done=false; cycle_count=0
        while true; do
            if ! is_boot_completed; then sleep 5; continue; fi
            if [ "$keybox_setup_done" = false ]; then setup_keybox_environment 1; keybox_setup_done=true; fi
            current_state=""; found_any=false; found_attestation_app=false
            while IFS= read -r pkg || [ -n "$pkg" ]; do
                case "$pkg" in ""|\#*) continue ;; esac
                if is_app_running "$pkg"; then
                    current_state="${current_state}${pkg};"; found_any=true
                    if is_attestation_app "$pkg"; then found_attestation_app=true; fi
                fi
            done < "$MODPATH/target_apps.txt"
            if [ "$found_any" = true ]; then sleep_interval=3; else sleep_interval=10; fi
            if [ "$current_state" != "$last_state" ]; then
                if [ -n "$current_state" ]; then
                    log_msg "INFO" "Targets: $current_state"
                    spoof_bootloader_locked; hide_build_properties; hide_magisk_traces
                    if [ "$found_attestation_app" = true ]; then
                        log_msg "INFO" "Attestation app detected"
                        spoof_keybox_properties; hide_keystore_traces
                    fi
                fi
                last_state="$current_state"
            fi
            echo "$$" > "$MODPATH/.monitor_pid"
            cycle_count=$((cycle_count + 1))
            if [ "$cycle_count" -ge 3600 ]; then
                cycle_count=0
                [ -f "$MODPATH/keybox_updater.sh" ] && sh "$MODPATH/keybox_updater.sh" --check >/dev/null 2>&1 &
            fi
            sleep "$sleep_interval"
        done
    ' >/dev/null 2>&1 & )
    sleep 1
    if [ -f "$PID_FILE" ]; then
        MON_PID=$(cat "$PID_FILE" 2>/dev/null)
        log_msg "INFO" "Monitor PID: $MON_PID"
    fi
}

start_monitor
log_msg "INFO" "Service spawn complete"
exit 0
