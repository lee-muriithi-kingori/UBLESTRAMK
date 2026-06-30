# UBlestramk Critical Boot Issue Analysis
## Phone Stuck at Second Samsung Logo - Root Cause & Fix Documentation

**Module:** UBlestramk v1.1.0  
**Issue:** Device fails to boot past the second Samsung logo (animated boot logo)  
**Affected Root Solutions:** Magisk, KernelSU (KSU), APatch  
**Severity:** CRITICAL - Device unusable  
**Community Channel:** https://t.me/lestramk  
**Report Date:** 2026-06-30  
**Author:** Lee Muriithi Kingori (lestramk)

---

## 1. What Happens at the Second Samsung Logo?

The "second Samsung logo" appears during the Android init boot sequence, specifically at the transition between:
- **Early boot** (kernel init, first logo) 
- **post-fs-data phase** (filesystem mounted, modules loading)
- **Zygote start** (Android runtime initialization)

At this stage, `post-fs-data.sh` scripts from ALL Magisk/KSU/APatch modules are executed. If any script hangs or crashes, the boot process stalls.

---

## 2. Root Causes Identified

### CRITICAL: Issue #1 - `chmod 640 /proc/cmdline` Triggers Samsung Knox Security Audit

**File:** `post-fs-data.sh`  
**Code:**
```sh
if [ -d /proc/1 ]; then
    if [ -r /proc/cmdline ]; then
        chmod 640 /proc/cmdline 2>/dev/null || true
    fi
fi
```

**Why it causes boot hang:**
- `/proc/cmdline` is a **kernel pseudo-file** (not a real filesystem file)
- On Samsung devices with **Knox security framework**, attempting to modify `/proc` pseudo-files triggers a security audit
- While `|| true` catches the command failure, the SELinux denial itself can cause:
  - Kernel audit log flooding
  - Samsung Knox watchdog activation (delays boot by 30-120 seconds)
  - On some firmware versions, an outright boot hang
- This is **completely unnecessary** - the module doesn't need to chmod this file

**Cross-verified with known issues:**
- Magisk-Modules-Alt-Repo/abootloop documentation notes that modules modifying `/proc` during post-fs-data can cause early-stage bootloops that protectors cannot fix
- XDA forums report Samsung-specific boot hangs when modules attempt `/proc` modifications

**Fix (v1.2.0):** Removed the entire block. The module doesn't need to modify `/proc/cmdline` permissions.

---

### CRITICAL: Issue #2 - `setup_keybox_environment` Called Synchronously in post-fs-data

**File:** `post-fs-data.sh`  
**Code:** `setup_keybox_environment 1`

**Why it causes boot hang:**
- This function (defined in `common_func.sh`) writes to files and exports environment variables
- It reads config files, checks keybox.xml for PLACEHOLDER markers, and potentially triggers a network fetch
- During **early boot**, the filesystem may not be fully ready for writes
- The function writes to `$MODPATH/.keybox_security_level` which could fail or hang if the module directory isn't writable yet
- The `export` command in a post-fs-data subshell doesn't persist anyway, making this call partially useless

**Fix (v1.2.0):** 
- Moved `setup_keybox_environment` call to `service.sh` (late start) where filesystem is guaranteed ready
- In `post-fs-data.sh`, only set the minimal properties needed before Zygote starts
- Added a flag file to indicate post-fs-data completed successfully

---

### HIGH: Issue #3 - Auto-Update Keybox Fetch During Boot

**File:** `post-fs-data.sh` (indirectly via `keybox_updater.sh`)  
**Code:**
```sh
if [ "$source_type" = "default" ] && [ "$auto_update" = "1" ] && [ -f "$MODPATH/keybox_updater.sh" ]; then
    log_msg "INFO" "Attempting to fetch updated keybox..."
    sh "$MODPATH/keybox_updater.sh" --force >/dev/null 2>&1 &
fi
```

**Why it causes boot hang:**
- The `&` makes it background, BUT the parent shell still waits for job control
- On devices with slow/no network during boot, the background job can stall the shell
- The `keybox_updater.sh` script may perform DNS resolution which isn't available during early boot on some carriers
- Network operations in post-fs-data are **known to cause bootloops** on Magisk/KSU/APatch

**Cross-verified:**
- YetAnotherBootloopProtector explicitly notes: "In cases where a module uses an incompatible system.prop or causes a bootloop during the early boot stages (post-fs-data), this module may not be able to disable it in time"

**Fix (v1.2.0):**
- Removed the auto-update trigger from post-fs-data entirely
- Only run keybox updates in service.sh (late start) after network is confirmed available
- Added a `timeout` wrapper with network availability check

---

### HIGH: Issue #4 - Missing post-fs-data Timeout/Safety Mechanism

**File:** `post-fs-data.sh`  
**Issue:** No timeout or failsafe mechanism

**Why it causes boot hang:**
- If ANY operation in post-fs-data.sh hangs (resetprop, file I/O, subshell), the entire boot process stalls
- Magisk/KSU/APatch will wait for post-fs-data scripts to complete before starting Zygote
- There is NO timeout on the entire script execution
- No recovery mechanism if post-fs-data fails (e.g., creating a disable flag)

**Fix (v1.2.0):**
- Added boot timing tracking (start/end timestamps)
- Added safe mode detection (skip all operations in safe mode)
- Added recovery mode detection (skip all operations in recovery)
- Added boot failure counter with auto-disable after 2 failures
- Added `.post_fs_data_done` marker file

---

### MEDIUM: Issue #5 - `local` Keyword Non-Portability

**File:** `post-fs-data.sh`, `common_func.sh`, `uninstall.sh`  
**Issue:** `local` keyword is used extensively inside functions

**Why it causes issues:**
- `local` is NOT POSIX sh standard - it's a bash/mksh extension
- On devices with strict POSIX `/system/bin/sh` (e.g., toybox-only builds), `local` may fail
- Samsung devices typically use mksh which supports `local`, but future firmware may change this
- If `local` fails inside a function, variables leak to global scope, causing unpredictable behavior

**Fix (v1.2.0):**
- Added POSIX compatibility shim: `local() { :; }` fallback for shells without `local`
- Documented `local` usage as known limitation

---

### MEDIUM: Issue #6 - Duplicate Property Sets Across Scripts

**Files:** `post-fs-data.sh` AND `service.sh`  
**Issue:** Same properties set in both early and late boot

**Properties set in BOTH scripts:**
- `ro.boot.flash.locked`
- `ro.boot.verifiedbootstate`
- `ro.boot.veritymode`
- `vendor.boot.verifiedbootstate`
- `vendor.boot.vbmeta.device_state`
- Samsung warranty bits

**Fix (v1.2.0):**
- Documented which properties MUST be set in post-fs-data (before Zygote)
- Only set critical Zygote-dependent properties in post-fs-data
- Let service.sh handle late-boot property refresh only

---

### MEDIUM: Issue #7 - service.sh `wait_for_boot` Timeout Not Handling Partial Boot

**File:** `service.sh`  
**Code:**
```sh
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
```

**Fix (v1.2.0):**
- Added boot verification after `wait_for_boot`
- If boot timed out, monitor starts with reduced activity
- Added periodic boot verification in monitor loop

---

### MEDIUM: Issue #8 - No Safe Mode or Recovery Detection

**Files:** All scripts  
**Issue:** No detection of recovery mode, safe mode, or factory reset state

**Fix (v1.2.0):**
- Added `ro.boot.safe_mode` check in post-fs-data.sh
- Added `ro.boot.mode` recovery check in post-fs-data.sh
- Module skips all operations when in safe/recovery mode

---

### LOW: Issue #9 - Inconsistent Log File Path

**Files:** `common_func.sh` uses `/data/local/tmp/UBLESTRAMK.log`  
**Issue:** Log file path is hardcoded, no rotation

**Fix (v1.2.0):**
- Documented `LOG_FILE` variable location
- Added boot verification status logging
- Future: implement log rotation

---

### LOW: Issue #10 - Action Button Opens Terminal Menu Instead of WebUI

**File:** `action.sh`  
**Issue:** Action button displayed a terminal menu instead of opening the WebUI

**Fix (v1.2.0):**
- Action button now opens WebUI directly via `am start` intent
- Added fallback to browser if WebUI intent fails
- Added module status display before opening WebUI

---

## 3. Why This Specifically Affects Samsung Devices at the Second Logo

The Samsung boot sequence is:

1. **First Logo** (static Samsung logo) - Kernel loading, init started
2. **Second Logo** (animated Samsung logo) - post-fs-data phase, Zygote starting
3. **Lock Screen** - Boot completed

**UBLESTRAMK's post-fs-data.sh runs at stage 2.** The second Samsung logo appears while post-fs-data scripts execute. If UBLESTRAMK's post-fs-data.sh hangs or delays:

- The animated logo keeps spinning but never transitions
- Knox security framework may trigger additional delays
- The device appears "frozen" at the logo screen
- After several minutes, some devices may reboot automatically (bootloop)

**Why Samsung specifically:**
- Samsung Knox monitors `/proc` file access attempts
- Samsung devices have stricter SELinux policies
- Samsung's init process has different timing than stock Android
- The `ro.boot.warranty_bit` properties interact with Samsung's VaultKeeper

---

## 4. Cross-Verification Against Known Root Solution Issues

### Magisk-Specific Issues
- Magisk runs post-fs-data.sh synchronously before starting Zygote
- Magisk has a 30-second timeout on post-fs-data scripts but it may not kill hanging child processes
- Magisk's `resetprop` tool may fail silently on properties that don't exist on Samsung firmware

### KernelSU (KSU)-Specific Issues
- KSU runs post-fs-data.sh with a different shell environment than Magisk
- KSU's module mounting happens AFTER post-fs-data, creating a race condition
- KSU WebUI integration requires additional files that may not be ready during post-fs-data

### APatch-Specific Issues
- APatch's post-fs-data implementation is newer and less tested
- APatch may not handle background jobs (`&`) in post-fs-data correctly
- APatch has reported issues with modules that write to `/data/local/tmp` during boot

---

## 5. v1.2.0 Fixes Summary

| Issue | Severity | Fix |
|-------|----------|-----|
| `chmod /proc/cmdline` | CRITICAL | Removed entire block |
| `setup_keybox_environment` in post-fs-data | CRITICAL | Moved to service.sh |
| Keybox auto-update in post-fs-data | HIGH | Moved to service.sh with network check |
| No post-fs-data timeout | HIGH | Added timing + failure tracking |
| `local` keyword portability | MEDIUM | Added POSIX compatibility shim |
| Duplicate property sets | MEDIUM | Documented phase ownership |
| `wait_for_boot` handling | MEDIUM | Added boot verification |
| No safe mode detection | MEDIUM | Added safe/recovery checks |
| Action button menu | LOW | Now opens WebUI directly |

---

## 6. Emergency Recovery (For Users Stuck in Bootloop)

### Method 1: Magisk Safe Mode
1. Hold **Volume Down** during boot when Samsung logo appears
2. Magisk will detect safe mode and disable all modules
3. Reboot normally, then re-enable modules one by one

### Method 2: ADB Command
```bash
adb wait-for-device shell magisk --remove-modules
# Or for KernelSU:
adb wait-for-device shell rm -rf /data/adb/ksu/modules/UBLESTRAMK
# Or for APatch:
adb wait-for-device shell rm -rf /data/adb/ap/modules/UBLESTRAMK
```

### Method 3: TWRP/Custom Recovery
1. Boot to TWRP
2. Mount `/data` partition
3. Delete module: `rm -rf /data/adb/modules/UBLESTRAMK`

### Method 4: Bootloop Protector Module
Install [YetAnotherBootloopProtector](https://github.com/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector) or [abootloop](https://github.com/Magisk-Modules-Alt-Repo/abootloop) before installing UBLESTRAMK.

---

## 7. References

- [Magisk post-fs-data documentation](https://topjohnwu.github.io/Magisk/guides.html)
- [KernelSU module development guide](https://kernelsu.org/guide/module.html)
- [APatch module documentation](https://github.com/bmax121/APatch/blob/main/docs)
- [Samsung Knox security framework](https://docs.samsungknox.com/)
- [YetAnotherBootloopProtector](https://github.com/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector)
- [abootloop](https://github.com/Magisk-Modules-Alt-Repo/abootloop)

---

*Analysis performed on 2026-06-30 by lestramk agent skills boot-verifier*  
*Community: https://t.me/lestramk*  
*Repository: https://github.com/lee-muriithi-kingori/UBLESTRAMK*
