# UBLESTRAMK <v1.4.0>

**Universal Boot-Lock Evasion & Stealth Root Admin Module**

> Devs shouldn't pay for fear.

Hide root from Uber Driver, banking apps, streaming services, and more. For Magisk 24+, KernelSU, and APatch.

## What's New in v1.4.0

- **Full WebUI Settings Persistence** - Settings now survive reboots and are stored atomically
- **POSIX Compliance** - Works on Android 15+ with strict POSIX shells
- **Single-File WebUI** - Self-contained dashboard, no build step needed
- **Real-Time Status** - Live boot verification, keybox state, and shield status
- **Enhanced Keybox Updater** - Retry logic, file locking, backup rotation
- **Build Validation** - `./build.sh --check-only` validates everything

## Features

| Feature | Description |
|---------|-------------|
| Boot Lock Spoofing | Reports locked bootloader to apps |
| Keystore Attestation | Bypasses hardware attestation checks |
| WebUI Dashboard | Full-featured config panel with persistence |
| Auto Keybox Updates | Self-updating keybox from trusted sources |
| 45+ Target Apps | Banking, ride-sharing, streaming, games |
| Cross-Manager | Works on Magisk, KernelSU, and APatch |
| Boot Verification | Self-test system with health reporting |

## Quick Start

1. Download `UBLESTRAMK-v1.4.0.zip` from [Releases](../../releases)
2. Install via your root manager (Magisk/KernelSU/APatch)
3. **Reboot** your device
4. Open the WebUI:
   - **KernelSU/APatch**: Tap the UBLESTRAMK module card
   - **Magisk**: Tap the action (play) button
5. Add target apps to your DenyList/Unmount modules list
6. Clear target app data

## Target Apps

**Ride Sharing**: Uber Driver, Uber, Uber Eats, Bolt
**Banking (US)**: Chase, Bank of America, Wells Fargo, PayPal, Venmo
**Banking (Kenya)**: M-Pesa, Equity, KCB, Co-op, Absa, Stanbic
**Fintech (Nigeria)**: Opay, PalmPay, Kuda
**Fintech (Global)**: Chipper Cash, Revolut, Wise
**Streaming**: Netflix, Disney+, Hulu, Spotify
**Games**: Pokemon GO, Clash of Clans
**Enterprise**: Microsoft Teams, Slack, Zoom

## WebUI Dashboard

The WebUI provides:
- **Protection Settings**: Toggle bootloader spoof, build props, keystore hiding
- **Keybox Config**: Source type, security level (TEE/StrongBox/Software), attestation mode
- **Target Apps**: Visual list of all 45+ target apps with categories
- **Module Logs**: Live log viewer with color-coded severity
- **Actions**: Force keybox update, run hide now, validate keybox

## Building from Source

```bash
# Validate only
./build.sh --check-only

# Build
./build.sh v1.4.0

# Output: build/ and output/ directories
```

## Community

- **Telegram**: [@lestramk](https://t.me/lestramk)
- **GitHub Issues**: [Report bugs](../../issues)
- **GitHub Sponsors**: [Support development](https://github.com/sponsors/lee-muriithi-kingori)

## Credits

- [chiteroman](https://github.com/chiteroman) - Original PlayIntegrityFix
- [osm0sis](https://github.com/osm0sis) - PlayIntegrityFork
- [Yuri](https://t.me/YuriKeyboxManager) - Keybox Manager
- [Tricky Store](https://github.com/5ec1cff/TrickyStore) - Keybox injection
- All contributors in the Android rooting community

## License

See [LICENSE](LICENSE)

---

**Disclaimer**: This module is for educational and personal use on devices you own. Bypassing security checks may violate terms of service. Use at your own risk.
