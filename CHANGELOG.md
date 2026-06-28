# Changelog

All notable changes to UBLESTRAMK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.9.0-beta] - 2025-01-XX

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
- [ ] Community feedback integration
- [ ] Expanded OEM support
- [ ] Improved Zygisk hiding
- [ ] Auto-detection of hiding requirements
- [ ] GUI configuration app

### v1.1.0
- [ ] Play Integrity API bypass helpers
- [ ] Automatic target app detection
- [ ] Performance optimizations

### v2.0.0
- [ ] Standalone mode (no Zygisk required)
- [ ] Kernel-level hiding for KernelSU
- [ ] Advanced anti-detection techniques

---

*Devs shouldn't pay for fear.*
