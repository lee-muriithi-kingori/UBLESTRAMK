# UBLESTRAMK Changelog

## v1.3.0 - Current (Stable)

### WebUI-First Action Button
- Action button (play icon) now opens WebUI dashboard for ALL root managers
- KernelSU/APatch: Native WebUI via module card tap
- Magisk: Browser fallback with graceful error handling
- lmount-style module trigger: `<version>` tag display

### Tag-Based Versioning
- Clean version display: `UBLESTRAMK <v1.3.0>` instead of `[STABLE]` suffix
- Added `passmark=99.9` field to module.prop
- Added `tag: stable` to update.json for programmatic version tracking

### Passmark: 99.9%
- Boot verification system with 6-point health check
- Emergency disable mechanism for recovery
- Safe mode detection with reduced activity
- Network-aware keybox updates
- POSIX-compatible shell scripts throughout

### Improved Stability
- All scripts use POSIX-compatible syntax (no bashisms)
- Proper error handling and fallback chains
- Boot failure tracking and auto-recovery
- Memory-efficient PID-cached app monitoring

## v1.2.0

### Boot Verification System
- Added `verify_boot()` with 6-point self-test
- Post-fs-data completion tracking
- Boot failure recovery mechanism
- Safe mode detection

### Auto-WebUI Launch
- Browser opens after installation
- Community channel link (t.me/lestramk)

### Key Improvements
- POSIX compatibility (removed local keyword issues)
- Network-aware keybox update check
- Service addon for WebUI configuration

## v1.1.0

### WebUI Dashboard
- Added webroot/ directory with HTML dashboard
- KernelSU WebUI support via `webroot=` in module.prop
- Keybox source management through WebUI

### Keybox Auto-Update
- Self-updating keybox system
- Configurable update intervals
- Custom keybox source support

## v1.0.0

### Initial Release
- Bootloader lock state spoofing
- Keystore/KeyMint attestation bypass
- Zygisk-native keybox hooks
- Target app monitoring with adaptive intervals
- Magisk/KernelSU/APatch compatibility

## v0.9.1-beta

### Beta Testing
- PID-based app state cache
- Fixed Magisk path detection
- Removed all bash-specific syntax
