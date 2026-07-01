# UBLESTRAMK <v1.4.1>

**Universal Boot-Lock Evasion & Stealth Root Admin Module**

> Devs shouldn't pay for fear.

Hide root from Uber Driver, banking apps, streaming services, and more. For Magisk 24+, KernelSU, and APatch.

## What's New in v1.4.1

- **Native Zygisk C++ Layer**: Real `root_spoof.cpp` with process-info hiding hooks — strips Magisk/KSU markers from `/proc/self/status` and `/proc/self/mounts`
- **Keystore Hiding at Boot**: `hide_keystore_traces()` now runs during `post-fs-data` stage (before Zygote), not just in the monitor loop — apps that check traces early are now covered
- **Monitor Loop Config Reload**: Monitor now calls `reload_configs()` each cycle and reads actual config from disk instead of hardcoded defaults — WebUI toggle changes take effect immediately
- **Keystore Hiding on Manual Run**: `hide_root.sh` now also calls `hide_keystore_traces()` on manual invocation
- **Proper `local` Removal**: Removed the broken POSIX shim (`local() { :; }` detection pattern) — all scripts now use plain variable assignment compatible with both bash and POSIX sh

## Features

| Feature | Description |
|---------|-------------|
| Boot Lock Spoofing | Reports locked bootloader to apps |
| Keystore Attestation | Bypasses hardware attestation checks |
| Zygisk Native Layer | C++ hooks for undetectable process hiding |
| WebUI Dashboard | Full-featured config panel with persistence |
| Auto Keybox Updates | Self-updating keybox from trusted sources |
| 45+ Target Apps | Banking, ride-sharing, streaming, games |
| Cross-Manager | Works on Magisk, KernelSU, and APatch |
| Boot Verification | Self-test system with health reporting |

## Quick Start

1. Download `UBLESTRAMK-v1.4.1.zip` from [Releases](../../releases)
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

## Building from Source

```bash
# Validate only
./build.sh --check-only

# Build (requires Android NDK for native layer)
./build.sh v1.4.1

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
