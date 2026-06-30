# UBLESTRAMK [STABLE]

> **Universal Boot-Lock Evasion & Stealth Root Admin Module**
>
> *Because developers shouldn't pay for fear.*

[![Version](https://img.shields.io/badge/version-v1.1.0-green.svg)](https://github.com/lee-muriithi-kingori/UBLESTRAMK/releases)
[![Author](https://img.shields.io/badge/author-lee--muriithi--kingori-green.svg)](https://github.com/lee-muriithi-kingori)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-STABLE-green.svg)](https://github.com/lee-muriithi-kingori/UBLESTRAMK/issues)

---

## What's New in v1.1.0

### WebUI Dashboard
Access a comprehensive web interface directly from **KernelSU Manager**:
- **Dashboard** - View module status, keybox info, and device details
- **Keybox Manager** - Choose and configure your keybox source
- **Target Apps** - Manage which apps get root hidden
- **Logs** - View real-time module logs
- **Settings** - Configure attestation behavior

### Keybox Source Selection
You can now choose where your attestation keys come from:
- **Built-in Source** - Auto-managed, self-updating (default)
- **Custom URL** - Provide your own keybox.xml URL
- **Local File** - Use a keybox.xml on your device

### Self-Updating Keybox
The module automatically fetches the latest keybox configurations:
- Configurable update intervals
- Automatic validation of downloaded keyboxes
- Secure source obfuscation

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

### v1.1.0 - WebUI Dashboard
- **Full Web Interface** - Access from KernelSU Manager (tap module card)
- **Keybox Management** - Visual keybox source selection and configuration
- **Target App Manager** - Add/remove apps with one tap
- **Log Viewer** - Real-time filtered logs
- **Settings Panel** - Configure attestation mode, security level, and more

### v1.1.0 - Keybox Source Selection
- **Built-in Auto-Updating Source** - Automatically fetches latest keys
- **Custom URL Support** - Use your own trusted keybox source
- **Local File Support** - Offline keybox support
- **Source Obfuscation** - Default source URL is protected

### v1.1.0 - Hardware Attestation
- **Keybox Spoofing** - Spoofs hardware attestation certificate chain
- **TEE/StrongBox Spoofing** - Reports trusted execution environment
- **Play Integrity API** - Handles device integrity checks
- **Keystore Hiding** - Removes keystore injection markers

### Target Apps (Pre-configured)
- **Uber** (Driver, Rider, Eats)
- **Banking** (Chase, BofA, Wells Fargo, Citi, PayPal, Venmo)
- **Crypto** (Coinbase, Binance)
- **Streaming** (Netflix, Disney+, Hulu)
- **Games** (Pokemon GO, etc.)
- **Work** (Teams, Slack, Zoom)
- **Customizable** - Add any app you need

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
- Root access

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
2. Go to **Modules**
3. Tap on **UBLESTRAMK** card to open the WebUI
4. Configure your keybox source and target apps
5. Go to **App Profiles** or **SuperUser**
6. For each target app, enable **"Unmount modules"** / **"Exclude modifications"**
7. Install **ZygiskNext** if not already installed
8. Disable "Enforce DenyList" in ZygiskNext if present
9. Reboot

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

## WebUI Usage (KernelSU)

The WebUI provides a graphical interface for managing UBLESTRAMK:

### Accessing the WebUI
1. Open **KernelSU Manager**
2. Go to the **Modules** tab
3. Tap on the **UBLESTRAMK** module card
4. The WebUI will open in a webview

### Dashboard
View your module status at a glance:
- Module active/inactive status
- Root solution detection
- Bootloader and keystore state
- Keybox information
- Device details

### Keybox Manager
Configure your hardware attestation keys:
1. **Built-in Source** (Recommended)
   - Automatically updates with latest keys
   - Set your preferred update interval
   - Enable/disable auto-update

2. **Custom URL**
   - Enter your trusted keybox.xml URL
   - Module will fetch from your source
   - Still supports auto-update

3. **Local File**
   - Place your keybox.xml in the module directory
   - Module will use it directly

### Target Apps
Manage which apps get root hidden:
- View currently configured apps
- See which apps are currently running
- Apps using attestation are marked
- Toggle apps on/off
- Add new apps by package name
- Remove apps you don't need

### Logs
View module activity in real-time:
- Filter by log level (Info, Warn, Error, Debug)
- Auto-refreshing log stream
- Clear logs when needed

### Settings
Configure attestation behavior:
- **Attestation Mode**: Spoof / Block / Pass-through
- **Security Level**: TEE / StrongBox / Software
- **Spoof Bootloader**: Enable/disable bootloader spoofing
- **Spoof Properties**: Enable/disable property hiding
- **Hide Keystore**: Enable/disable keystore trace removal

---

## Customization

### Adding Target Apps (via WebUI)
The easiest way is through the WebUI Target Apps tab. Just enter the package name and tap Add.

### Adding Target Apps (Manual)
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

### Keybox Source (via WebUI)
Use the Keybox Manager tab to select and configure your keybox source.

### Keybox Source (Manual)
Edit the configuration files in `/data/adb/modules/UBLESTRAMK/`:
- `.keybox_source_type` - `default`, `custom_url`, or `local_file`
- `.keybox_source_url` - Your custom URL (if using custom_url)
- `.keybox_auto_update` - `1` for enabled, `0` for disabled
- `.keybox_update_interval` - Hours between checks (default: 24)

### Force Keybox Update
Run manually:
```bash
su -c "sh /data/adb/modules/UBLESTRAMK/keybox_updater.sh --force"
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
- Periodically checks for keybox updates (v1.1.0)

### Layer 3: Keybox/Attestation Spoofing (v1.1.0)
- Intercepts hardware attestation requests
- Returns spoofed certificate chains
- Reports TEE/StrongBox security level
- Handles Play Integrity API checks

### Layer 4: Mount Unmounting
For target apps, module mounts are unmounted:
- `/data/adb/modules` - Hidden
- `/data/adb/ksu` - Hidden
- `/debug_ramdisk` - Hidden
- Module functionality preserved in other apps

### Layer 5: Zygisk Integration (Optional)
When Zygisk libraries are present, provides:
- Deeper system-level hiding
- PLT hook-based evasion
- Memory artifact cleanup
- Native library injection hiding

---

## Troubleshooting

### WebUI not showing in KernelSU?
- Make sure you're on KernelSU v0.7.0+
- The module must be enabled (not disabled)
- Try force-stopping KernelSU Manager and reopening

### Keybox update failing?
- Check your internet connection
- If using custom URL, verify the URL is accessible
- Check logs: `cat /data/local/tmp/UBLESTRAMK.log | grep Keybox`
- Try manual update: `sh /data/adb/modules/UBLESTRAMK/keybox_updater.sh --force`

### App still detects root?
1. **Clear app data completely** - Most important step!
2. **Check DenyList/Unmount** - Make sure the app is configured
3. **Check keybox status** - Use WebUI or action button option 3
4. **Reboot** - Some changes need a fresh boot
5. **Check logs** - `cat /data/local/tmp/UBLESTRAMK.log`
6. **Try ZygiskNext** - Install if not using it
7. **Disable other modules** - Some modules conflict

### Uber Driver specific issues:
- Make sure keybox has valid keys (not template)
- Clear Uber Driver data AND Google Play Services data
- Wait 24-48 hours after first setup (some checks are delayed)
- Use the WebUI to check keybox status

### Banking app crashes?
- Some banking apps use hardware attestation - this cannot be bypassed on all devices
- Try installing **Play Integrity Fix** module alongside UBLESTRAMK
- Older devices have better success rates
- Try different attestation modes in settings

### Bootloop?
- Boot into safe mode (volume down during boot)
- Or use ADB: `adb shell touch /data/adb/modules/UBLESTRAMK/disable`
- Or remove: `adb shell rm -rf /data/adb/modules/UBLESTRAMK`

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
