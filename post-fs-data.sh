#!/system/bin/sh
# ==========================================
# UBLESTRAMK - Post Filesystem Data Script
# Runs early in boot - before Zygote starts
#
# CHANGES (v0.9.1-beta):
# - Removed non-standard ro.boot.veritymode.managed property
#   This property doesn't exist in AOSP and serves as a unique
#   fingerprint for detection heuristics. (fixes issue #5)
# - Removed no-op chmod calls on sysfs pseudo-files
#   (/sys/fs/selinux/enforce and policy are kernel-controlled;
#   chmod on sysfs has no effect on most Android kernels)
# - Added comment explaining the /proc/cmdline permission change
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

# NOTE: Removed ro.boot.veritymode.managed property.
# This is a non-standard property that does not exist in AOSP.
# Its presence creates a unique fingerprint that sophisticated
# root detection can use to identify UBLESTRAMK specifically.
# The standard ro.boot.veritymode is already set to 'enforcing'
# in system.prop, which is the correct and sufficient way to
# spoof verified boot state.

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

# NOTE: sysfs pseudo-files (like /sys/fs/selinux/enforce) are
# backed by kernel handlers. Changing their permissions via chmod
# is a no-op on virtually all Android kernels. The proper way to
# hide permissive SELinux is via resetprop (done above) — the
# property value is what apps read, not the sysfs node directly.
# We leave sysfs alone to avoid log noise and false confidence.

# Clean any root indicators in /proc
if [ -d /proc/1 ]; then
    # Restrict kernel command line read access (may contain root flags)
    # Note: this only works if the post-fs-data script has sufficient
    # privilege, which varies by root solution version.
    if [ -r /proc/cmdline ]; then
        chmod 640 /proc/cmdline 2>/dev/null || true
    fi
fi

# Create module flag file for Zygisk detection
if [ -d "$MODPATH/zygisk" ]; then
    log_msg "INFO" "Zygisk libraries detected"
fi

log_msg "INFO" "=== post-fs-data completed ==="
