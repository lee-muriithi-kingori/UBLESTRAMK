#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Post Filesystem Data Script
# Runs early in boot - before Zygote starts
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

# Verity mode
resetprop_if_diff ro.boot.veritymode.managed yes

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

# Handle permissive SELinux - mask it
if [ "$(cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce 2>/dev/null
    chmod 440 /sys/fs/selinux/policy 2>/dev/null
    log_msg "INFO" "Masked permissive SELinux"
fi

# Clean any root indicators in /proc
if [ -d /proc/1 ]; then
    # Hide kernel command line root flags
    if [ -r /proc/cmdline ]; then
        chmod 640 /proc/cmdline 2>/dev/null || true
    fi
fi

# Create module flag file for Zygisk detection
if [ -d "$MODPATH/zygisk" ]; then
    log_msg "INFO" "Zygisk libraries detected"
fi

log_msg "INFO" "=== post-fs-data completed ==="
