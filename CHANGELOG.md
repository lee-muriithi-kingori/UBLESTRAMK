# Changelog

All notable changes to UBLESTRAMK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0] - 2026-06-30

### MAJOR FEATURE: Hardware Attestation Bypass (Keybox/Keystore)

This release introduces comprehensive hardware attestation bypass capabilities, targeting banking apps, rideshare platforms, and streaming services that use Google Play Integrity API with hardware-backed key attestation.

### Added

#### Keybox/Keystore Attestation Hooking
- **Native keybox hooking subsystem** (`zygisk_src/jni/keybox_hook.cpp/.h`):
  - Intercepts `KeyGenParameterSpec.Builder.setAttestationChallenge()` calls
  - Hooks `IKeyMintDevice` attestation certificate generation
  - Provides pre-generated certificate chains (TEE + Google Root CA)
  - Supports TEE (`ro.hardware.keystore=teetz`) and StrongBox security level spoofing
  - Configurable attestation mode: spoof, block, or pass-through
  - Validates `keybox.xml` at module load time

- **Attestation certificate templates**:
  - Google Hardware Attestation Root CA (public)
  - Device attestation certificate (TEE-backed template)
  - Certificate chain generation for `getAttestationCertificate()` responses

- **Target app attestation detection** — Automatically applies keybox hiding for 22+ known attestation apps:
  - Banking: Chase, BofA, Wells Fargo, PayPal, Venmo, M-Pesa, Equity, KCB, Co-op, Absa, Opay, PalmPay, Kuda, Chipper, Revolut, Wise
  - Rideshare: Uber (Driver/Rider/Eats), Bolt
  - Streaming: Netflix
  - Games: Pokemon GO
  - Enterprise: Microsoft Teams

- **Keybox configuration file** (`keybox.xml`):
  - Standard Android keybox.xml format
  - Supports EC P-256 and RSA 2048 keys
  - Configurable security level and attestation mode
  - Property spoofing section (`ro.boot.verifiedbootstate=green`, etc.)
  - Template with PLACEHOLDER markers for real key insertion

#### Enhanced Property Spoofing
- **Keystore backend properties** (early boot spoofing):
  - `ro.hardware.keystore=teetz` (TEE backend)
  - `ro.hardware.keymint=trusty` (KeyMint HAL)
  - `ro.hardware.gatekeeper=teetz` (Gatekeeper)
  - `ro.security.keystore.deserializer_type=tee`
  - `ro.crypto.state=encrypted` (crypto consistency)

- **New functions in `common_func.sh`**:
  - `spoof_keybox_properties()` — Spoofs all keystore/keymint properties
  - `setup_keybox_environment()` — Sets security level for Zygisk hooks
  - `hide_keystore_traces()` — Removes keystore-related root indicators
  - `is_attestation_app()` — Detects apps known to use hardware attestation
  - Enhanced `monitor_target_apps()` applies keybox hiding for attestation apps

#### Enhanced Zygisk Module
- **Integrated keybox hooks** in `main.cpp`:
  - `keybox_init()` called during module load
  - `keybox_hook_process()` applied per target app
  - `keybox_cleanup()` on system server specialize
  - Logs keybox activity to Android logcat

### Changed
- **Version bump**: v0.9.1-beta → v1.0.0 (stable)
- **module.prop**: Updated description to highlight keybox/attestation features
- **system.prop**: Added keystore/keymint/crypto properties
- **post-fs-data.sh**: Added early-boot keybox property spoofing, keybox.xml validation
- **Android.mk**: Added `keybox_hook.cpp` to native build

### How to Use Keybox Features

1. **Basic setup** (works out of the box):
   ```bash
   # Install v1.0.0 module
   # Keybox TEE spoofing is active by default
   # Apps requesting attestation get spoofed certificates
   ```

2. **Insert real keys** (better compatibility):
   ```bash
   # Extract keybox from a stock device:
   adb shell su -c "cat /data/misc/keystore/persistent.sqlite" > keystore.db
   # Extract keys and replace PLACEHOLDER values in keybox.xml
   ```

3. **Configure security level**:
   ```bash
   # Edit keybox.xml:
   # <SpoofedSecurityLevel>tee</SpoofedSecurityLevel>
   # Options: tee, strongbox, software
   ```

4. **Block attestation entirely** (for stubborn apps):
   ```bash
   # Set environment variable:
   export UBLESTRAMK_BLOCK_ATTESTATION=1
   ```

### Known Limitations
- Spoofed certificates pass app-side parsing but may fail Google server-side verification
- Apps using server-backed integrity checks may still fail (expected behavior)
- For full bypass, real device attestation keys are recommended

---

## [v0.9.1-beta] - 2026-06-29

### Fixed
- **ro.boot.mode** changed from `unknown` to `boot` — `unknown` is an anomalous value that triggers detection heuristics in Samsung Knox and some banking apps. `boot` is the standard AOSP normal-boot value. ([#4](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues/4))
- **Amazon Music package name** — corrected from deprecated `com.amazon.mp3.android` to current `com.amazon.mp3`. ([#6](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues/6))
- **Removed non-standard property** — eliminated `ro.boot.veritymode.managed=yes` which is not an AOSP property and creates a unique fingerprint for detection databases. ([#5](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues/5))

### Added
- **African banking & fintech apps** — added 13 new targets critical for the primary user base (Kenyan Uber drivers): ([#2](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues/2))
  - Kenya: M-Pesa (`com.safaricom.mpesa.lifestyle`), Equity (`com.equitybank.equityjiunge`), KCB (`com.kcbgroup.kcbpip`), Co-operative Bank, Absa, Stanbic
  - Nigeria: Opay, PalmPay, Kuda Bank
  - Pan-Africa: Chipper Cash
  - Global fintech: Revolut, Wise
  - Ride-sharing: Bolt Driver (`ee.mtakso.client`)
- **Removed Samsung Pay** — requires hardware Knox attestation which this module cannot bypass; including it provided false confidence.

### Performance
- **PID-based app state cache** — monitor loop now caches process IDs, reducing `pidof` calls by ~70% during idle. ([#7](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues/7))
- **Adaptive sleep interval** — 10 seconds when no targets running (was 3s fixed), 3 seconds when targets detected. Significant battery savings on devices with many target apps.

### Security
- Reduced detection surface by removing fingerprintable non-standard properties.
- Monitor loop now verifies cached PIDs against `/proc/${pid}/cmdline` to prevent PID-reuse false positives.

---

## [v0.9.0-beta] - 2026-06-28

### Added - Initial Beta Release
- **Core Module Structure** - Complete Magisk/KernelSU/APatch compatible module
- **Bootloader Spoofing** - Simulates locked bootloader state:
  - `ro.boot.verifiedbootstate=green`
  - `ro.boot.flash.locked=1`
  - `ro.boot.veritymode=enforcing`
  - `ro.boot.vbmeta.device_state=locked`
- **Multi-OEM Support** - Samsung, OnePlus, Realme, Oppo, Xiaomi, Google
  - Samsung Knox warranty bits spoofing
  - OnePlus verified boot state
  - Realme/Oppo boot state
- **Property Masking** - Comprehensive build property hiding:
  - `ro.build.tags=release-keys`
  - `ro.build.type=user`
  - `ro.debuggable=0`
  - `ro.secure=1`
- **Continuous Monitoring** - Background service that watches for target apps
- **Target App List** - Pre-configured apps including:
  - Uber (Driver, Rider, Eats)
  - Banking (Chase, BofA, Wells Fargo, Citi, PayPal, Venmo)
  - Crypto (Coinbase, Binance)
  - Streaming (Netflix, Disney+, Hulu)
  - Games (Pokemon GO)
- **Mount Unmounting** - Unmounts module paths for target apps
- **Zygisk Native Module** - C++ library for deeper system-level hiding
- **On-Demand Hiding** - Manual trigger via `/data/adb/modules/UBLESTRAMK/hide_root.sh`
- **Action Button** - Quick re-apply from Magisk/KernelSU Manager
- **Comprehensive Logging** - Detailed logs at `/data/local/tmp/UBLESTRAMK.log`
- **Safe Uninstall** - Clean removal script
- **Flashable ZIP** - Ready-to-install package
- **CI/CD Pipeline** - GitHub Actions automated build
- **Update System** - Magisk/KernelSU compatible update.json

### Known Issues (Beta)
- Some banking apps with hardware attestation may still detect root on newer devices
- SELinux permissive mode detection on some custom ROMs
- May need additional hiding modules (Shamiko, Play Integrity Fix) for some apps

### For Testing
- All Android versions 8.0+
- All root solutions (Magisk 26+, KernelSU, APatch)
- Report issues at: https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues

---

## Future Roadmap

### v1.1.0
- [ ] Automatic keybox extraction from companion device
- [ ] Certificate chain matching for popular device models
- [ ] Additional keystore property spoofing
- [ ] Performance: Lazy keybox initialization

### v1.2.0
- [ ] StrongBox emulation layer
- [ ] Google Play Integrity API server response mocking
- [ ] Kernel-level hiding for KernelSU
- [ ] Advanced anti-detection techniques

### v2.0.0
- [ ] Standalone mode (no Zygisk required)
- [ ] AI-powered dynamic detection evasion
- [ ] Auto-configuration based on device model

---

*Devs shouldn't pay for fear.*
