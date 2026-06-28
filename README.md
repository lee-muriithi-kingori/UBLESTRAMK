# UBLESTRAMK [BETA]

> **Universal Boot-Lock Evasion & Stealth Root Admin Module**
>
> *Because developers shouldn't pay for fear.*

[![Version](https://img.shields.io/badge/version-v0.9.0--beta-blue.svg)](https://github.com/lee-muriithi-kingori/UBLESTRAMK/releases)
[![Author](https://img.shields.io/badge/author-lee--muriithi--kingori-green.svg)](https://github.com/lee-muriithi-kingori)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-BETA-orange.svg)](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues)

---

## What is UBLESTRAMK?

**UBLESTRAMK** is a comprehensive root hiding module for Android devices that helps you use apps that normally block rooted devices. Whether you're an Uber driver trying to earn, someone who needs banking apps, or just believe you should control your own device - this module helps level the playing field.

**UBLESTRAMK** stands for:
- **U**niversal - Works across Magisk, KernelSU, and APatch
- **B**oot-**L**ock **E**vasion - Spoofs a locked bootloader
- **S**tealth **T**echnology - Hides root traces comprehensively  
- **R**oot **A**dmin **M**odule - Complete admin control
- **K**ingori - From the founder, for the community

---

## Features

### Core Capabilities
- **Universal Compatibility** - Works with Magisk, KernelSU, and APatch
- **Bootloader Spoofing** - Simulates a locked bootloader (`green` verified boot state)
- **Property Masking** - Spoofs build tags, boot state, warranty bits, and more
- **Module Unmounting** - Unmounts module files for target apps while keeping functionality
- **Continuous Monitoring** - Background service watches for target apps
- **Multi-OEM Support** - Samsung, OnePlus, Realme, Oppo, Xiaomi, Google, and more
- **Zygisk Integration** - Deep system-level hiding via Zygisk native libraries

### Target Apps (Pre-configured)
- **Uber** (Driver, Rider, Eats)
- **Banking** (Chase, BofA, Wells Fargo, Citi, PayPal, Venmo)
- **Crypto** (Coinbase, Binance)
- **Streaming** (Netflix, Disney+, Hulu)
- **Games** (Pokemon GO, etc.)
- **Work** (Teams, Slack, Zoom)
- **Customizable** - Add any app you need

### Advanced Features
- **On-Demand Hiding** - Manual trigger script for immediate hiding
- **Action Button** - Quick re-apply from Magisk/KernelSU Manager
- **Detailed Logging** - Full logs at `/data/local/tmp/UBLESTRAMK.log`
- **Safe Uninstall** - Clean removal without residue

---

## Requirements

| Root Solution | Minimum Version | Additional Requirements |
|--------------|----------------|------------------------|
| **Magisk** | v26.0+ (v27.0+ recommended) | Zygisk enabled |
| **KernelSU** | v0.7.0+ | ZygiskNext module |
| **APatch** | v10400+ | ZygiskNext module |

### General Requirements
- Android 8.0+ (API 26+)
- Zygisk or ZygiskNext installed
- Root access (obviously)

---

## Installation

### Step 1: Prepare Your Device
1. Make sure your root solution is up to date
2. Install **ZygiskNext** (for KernelSU/APatch) or enable **Zygisk** (for Magisk)

### Step 2: Install UBLESTRAMK
1. Download the latest `UBLESTRAMK-v*.zip` from [Releases](../../releases)
2. Open your root manager (Magisk/KernelSU/APatch)
3. Go to **Modules** → **Install from storage**
4. Select the downloaded ZIP file
5. Wait for installation to complete
6. **Reboot** your device

### Step 3: Configure (Important!)

#### For Magisk Users:
1. Go to Magisk **Settings**
2. Enable **Zygisk**
3. Turn **OFF** "Enforce DenyList"
4. Go to **Configure DenyList**
5. Check the apps you want to hide root from
6. Reboot

#### For KernelSU Users:
1. Open **KernelSU Manager**
2. Go to **App Profiles** or **SuperUser**
3. For each target app, enable **"Unmount modules"** / **"Exclude modifications"**
4. Install **ZygiskNext** if not already installed
5. Disable "Enforce DenyList" in ZygiskNext if present
6. Reboot

#### For APatch Users:
1. Open **APatch Manager**
2. Enable **"Unmount modules"** for target apps
3. Install **ZygiskNext** if not already installed
4. Reboot

### Step 4: Clear App Data
After first boot with UBLESTRAMK:
1. Go to **Settings** → **Apps**
2. Find your target app (e.g., Uber Driver)
3. Tap **Storage** → **Clear Data** / **Clear Cache**
4. Open the app - it should no longer detect root!

---

## Customization

### Adding Target Apps
Edit `/data/adb/modules/UBLESTRAMK/target_apps.txt` and add package names:

```
# My custom apps
com.mybank.app
com.mygame.app
```

Find package names using:
```bash
# Via ADB
adb shell pm list packages | grep appname

# Or use an app like "App Inspector" from Play Store
```

### Disabling Log Deletion
Create a file to skip property deletion:
```bash
touch /data/adb/modules/UBLESTRAMK/skipdelprop
```

### Manual Trigger
Run hiding on-demand:
```bash
sh /data/adb/modules/UBLESTRAMK/hide_root.sh
```

### View Logs
```bash
cat /data/local/tmp/UBLESTRAMK.log
```

---

## How It Works

### Layer 1: Property Spoofing (Early Boot)
`post-fs-data.sh` runs before Zygote starts, setting critical properties:
- `ro.boot.verifiedbootstate=green` (passes verified boot check)
- `ro.boot.flash.locked=1` (bootloader appears locked)
- `ro.build.tags=release-keys` (official build appearance)
- Samsung Knox warranty bits set to 0

### Layer 2: Continuous Monitoring (Service)
`service.sh` runs a background monitor that:
- Detects when target apps are launched
- Re-applies hiding properties dynamically
- Watches for property changes by the system

### Layer 3: Mount Unmounting
For target apps, module mounts are unmounted:
- `/data/adb/modules` - Hidden
- `/data/adb/ksu` - Hidden  
- `/debug_ramdisk` - Hidden
- Module functionality preserved in other apps

### Layer 4: Zygisk Integration (Optional)
When Zygisk libraries are present, provides:
- Deeper system-level hiding
- PLT hook-based evasion
- Memory artifact cleanup
- Native library injection hiding

---

## Troubleshooting

### App still detects root?

1. **Clear app data completely** - Most important step!
2. **Check DenyList/Unmount** - Make sure the app is configured
3. **Reboot** - Some changes need a fresh boot
4. **Check logs** - `cat /data/local/tmp/UBLESTRAMK.log`
5. **Try ZygiskNext** - Install if not using it
6. **Disable other modules** - Some modules conflict

### Uber Driver specific issues:
- Make sure you're on the latest version of the module
- Clear Uber Driver data AND Google Play Services data
- Wait 24-48 hours after first setup (some checks are delayed)

### Banking app crashes?
- Some banking apps use hardware attestation - this cannot be bypassed on all devices
- Try installing **Play Integrity Fix** module alongside UBLESTRAMK
- Older devices have better success rates

### Bootloop?
- Boot into safe mode (volume down during boot)
- Or use ADB: `adb shell touch /data/adb/modules/UBLESTRAMK/disable`
- Or remove: `adb shell rm -rf /data/adb/modules/UBLESTRAMK`

---

## BETA Status

This is a **BETA release** (v0.9.0-beta). This means:
- Active development is ongoing
- Community feedback is essential
- Some features may not work on all devices
- Updates will be frequent

**Your testing and bug reports help everyone!** Please report issues at:
https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues

Include:
- Device model
- Android version
- Root solution and version
- Target app name
- Log file contents

---

## The Story

> I'm Lee Muriithi Kingori - a developer and Uber driver from Kenya. Like many in the rooted community, I've been frustrated by apps that block rooted devices for no good reason. Root access is a legitimate tool for developers and power users - we shouldn't be punished for controlling our own devices.
>
> UBLESTRAMK was born from this frustration and the belief that **developers shouldn't pay for fear**. This module is for the community, by the community.
>
> - *lee-muriithi-kingori*

---

## Credits & Thanks

- **Zygisk-Assistant** by @snake-4 - Reference for Zygisk hiding techniques
- **Magisk** by @topjohnwu - The foundation of modern rooting
- **KernelSU** by @tiann - Kernel-level root solution
- **ZygiskNext** by @Dr-TSNG - Zygisk implementation
- **The Rooted Community** - For testing, feedback, and support

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Disclaimer

This module is provided for educational and legitimate purposes. Users are responsible for complying with applicable laws and terms of service. The author does not condone circumventing security measures for malicious purposes.

**Use at your own risk.** No warranty is provided. Always backup your device before installing modules.

---

## Connect

- **GitHub**: [@lee-muriithi-kingori](https://github.com/lee-muriithi-kingori)
- **Issues**: [UBLESTRAMK Issues](../../issues)
- **Sponsor**: [GitHub Sponsors](https://github.com/sponsors/lee-muriithi-kingori)

---

*Built with full autonomy. For the rooted community. Devs shouldn't pay for fear.*
