# UBLESTRAMK Changelog

## v1.4.0 (2026-06-30)

### Critical Fixes
- **WebUI Settings Persistence**: Complete rewrite of the WebUI dashboard - all settings now properly persist across reboots using atomic file writes via `window.ksu.exec()` API
- **POSIX Compliance**: Replaced non-portable `stat -c%s` with POSIX `wc -c` throughout all scripts (fixes Android 15+ compatibility)
- **Config Race Conditions**: All config writes now use atomic temp-file + rename pattern to prevent corruption

### New Features
- **Single-File WebUI**: New self-contained `index.html` with embedded CSS/JS - no build step needed, works immediately in KernelSU/APatch/Magisk
- **Auto-Save Toggles**: Settings changes are automatically saved when toggling switches or changing dropdowns
- **Real-Time Status**: Dashboard shows live module health (boot verification, keybox state, shield status)
- **Target App Categorization**: Apps displayed with category tags (Banking, Ride, Fintech, Streaming, etc.)
- **Log Viewer**: Built-in colored log viewer with refresh and clear buttons
- **Action Buttons**: Force keybox update, run hide now, validate keybox - all from the dashboard
- **Read-Only Mode**: Browser fallback gracefully shows read-only banner with manual instructions

### Build System
- **Validation Mode**: `./build.sh --check-only` validates entire module without building
- **Script Syntax Check**: All shell scripts validated with `sh -n` before packaging
- **WebUI Asset Validation**: Ensures index.html exists and references valid files
- **module.prop Validation**: Checks required fields, warns on anti-patterns
- **Proper Exit Codes**: Returns non-zero on validation failures for CI/CD integration

### Keybox Improvements
- **Download Retry**: Exponential backoff retry (3 attempts) for all downloads
- **File Locking**: Prevents concurrent keybox updates using mkdir-based lock
- **Backup Rotation**: Keeps last 5 keybox backups, removes older ones
- **Size Validation**: Rejects keyboxes under 100B or over 1MB
- **Enhanced Validation**: Checks XML structure, certificate count, placeholder detection
- **Network Check**: Validates internet connectivity before attempting download

### Security
- **Input Sanitization**: All config values sanitized to prevent shell injection
- **Log Sanitization**: Log messages stripped of non-printable characters
- **Temp File Cleanup**: Trap-based cleanup ensures no temp files left behind
- **PID File Management**: Monitor process tracks its PID for health monitoring

## v0.9.1-beta (2026-06-28)
- Bug fixes for ro.boot.mode, removed fingerprintable property
- Added 13 African banking and fintech apps
- ~70% CPU usage reduction with PID caching

## v0.9.0-beta (2026-06-28)
- Initial beta release
- Bootloader lock spoofing
- Keystore attestation bypass
- WebUI dashboard (basic)
- Keybox auto-updater
- 45+ target apps
