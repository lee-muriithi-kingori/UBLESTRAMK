# UBLESTRAMK Changelog

## v1.4.1 (2026-07-01)

### Bug Fixes

- **Keystore trace hiding at boot**: `hide_keystore_traces()` now runs during `post-fs-data` stage (before Zygote starts), not only in the monitor loop. Many banking/fintech apps check for Magisk/KSU keystore injection properties during their **very early initialization** — before the monitor loop ever runs.
- **Monitor loop config reload**: The service monitor now calls `reload_configs()` each cycle and reads actual config values from disk on every iteration, instead of using hardcoded defaults set at startup. WebUI toggle changes now take effect within seconds without restarting the service.
- **Keystore hiding on manual run**: `hide_root.sh` now also calls `hide_keystore_traces()` when invoked manually.
- **`local` keyword POSIX shim removal**: Removed the broken POSIX compatibility shim from `common_func.sh` (`local() { :; }` fallback defined after the detection check, making it ineffective). All scripts now use plain variable assignment compatible with both bash and POSIX sh.

### New Features

- **Native Zygisk C++ layer**: Added real `zygisk_src/jni/root_spoof.cpp`, `Android.mk`, and `Application.mk`. The C++ module provides process-info hiding hooks that shell scripts alone cannot achieve — strips Magisk/KSU markers from `/proc/self/status` and mount info reads, and provides spoofed Build properties via native code. Requires Android NDK to build (`./build.sh` detects it automatically).

### Chores

- Updated `build.sh` with Zygisk source validation and better native-build messaging
- Updated `META-INF/update-binary` (was previously absent from repo)
- Version bumped: v1.4.0 → v1.4.1, versionCode: 1400 → 1401

## v1.4.0 (2026-06-30)

- WebUI Settings Persistence (atomic file writes)
- POSIX Compliance (POSIX `wc -c` throughout)
- Single-File WebUI with embedded CSS/JS
- Real-Time Status (boot verification, keybox state, shield status)
- Enhanced Keybox Updater (retry logic, file locking, backup rotation)
- Build Validation (`./build.sh --check-only`)

## v0.9.1-beta (2026-06-28)
- Bug fixes for `ro.boot.mode`, removed fingerprintable property
- Added 13 African banking and fintech apps
- ~70% CPU usage reduction with PID caching

## v0.9.0-beta (2026-06-28)
- Initial beta release
- Bootloader lock spoofing
- Keystore attestation bypass
- WebUI dashboard (basic)
- Keybox auto-updater
- 45+ target apps
