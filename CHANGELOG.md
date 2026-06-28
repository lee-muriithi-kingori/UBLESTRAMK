# Changelog

All notable changes to UBLESTRAMK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### v1.0.0 (Stable)
- [x] Community feedback integration
- [x] Expanded OEM/regional app support
- [x] Performance optimizations
- [ ] Improved Zygisk hiding
- [ ] Auto-detection of hiding requirements
- [ ] GUI configuration app

### v1.1.0
- [ ] Play Integrity API bypass helpers
- [ ] Automatic target app detection
- [ ] Additional performance optimizations

### v2.0.0
- [ ] Standalone mode (no Zygisk required)
- [ ] Kernel-level hiding for KernelSU
- [ ] Advanced anti-detection techniques

---

*Devs shouldn't pay for fear.*
