# Changelog

All notable changes to UBLESTRAMK will be documented in this file.

## [v1.1.0] - 2026-06-30

### Added
- **WebUI Dashboard** - Full-featured web interface accessible from KernelSU Manager
  - Dashboard with module status, keybox info, and device information
  - Keybox Manager with source selection and auto-update controls
  - Target Apps management with add/remove/toggle functionality
  - Real-time Logs viewer with level filtering
  - Attestation Settings with configurable security levels
- **Keybox Source Selection** - Users can now choose their keybox source
  - Built-in auto-updating source (obfuscated URL for security)
  - Custom URL support for user-provided keybox sources
  - Local file support for offline keybox usage
- **Self-Updating Keybox** - Automatic keybox updates
  - Configurable update interval (6h, 12h, 24h, 48h, 72h)
  - Obfuscated default source with fallback chain
  - Automatic validation of downloaded keyboxes
  - Backup of current keybox before updates
- **Configuration Management** - Persistent settings via config files
  - `.keybox_source_type` - Source selection (default/custom_url/local_file)
  - `.keybox_auto_update` - Enable/disable auto-updates
  - `.keybox_update_interval` - Update frequency
  - `.attestation_mode` - spoof/block/pass_through
  - `.keybox_security_level` - tee/strongbox/software
  - Individual feature toggles (.spoof_bootloader, .spoof_properties, .hide_keystore)

### Changed
- Enhanced `service.sh` with integrated keybox periodic update checking
- Enhanced `common_func.sh` with configuration read/write helpers
- Enhanced `post-fs-data.sh` with config-aware property spoofing
- Enhanced `action.sh` with keybox management options
- Enhanced `customize.sh` with WebUI setup and v1.1.0 feature announcements
- Enhanced `uninstall.sh` with complete config cleanup
- Updated `module.prop` with new version and webroot support

### Security
- Default keybox source URL is obfuscated using base64 encoding
- Source URL is split into multiple parts and reconstructed at runtime
- Fallback sources available if primary source fails
- No source URL is revealed in WebUI when using built-in source

## [v1.0.0] - 2026-06-28

### Added
- Hardware attestation bypass (keybox/keystore)
- Keybox XML configuration file
- Keystore property spoofing (TEE/StrongBox)
- Keybox environment setup for Zygisk hooks
- Attestation app detection in monitor loop
- Enhanced property spoofing for banking/ride apps

### Changed
- Major version bump from BETA to STABLE

## [v0.9.1-beta] - 2026-06-26

### Fixed
- Removed `export -f` bashism causing compatibility issues
- Removed duplicate property sets
- Fixed `is_magisk()` to not rely on deprecated `/sbin` paths
- Added PID-based app state cache for performance

## [v0.9.0-beta] - 2026-06-24

### Added
- Initial BETA release
- Universal root hiding for Magisk/KernelSU/APatch
- Bootloader spoofing (locked state)
- Property masking
- Module unmounting
- Continuous monitoring
- Multi-OEM support
- Zygisk integration
