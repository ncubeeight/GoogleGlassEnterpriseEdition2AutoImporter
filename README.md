# Google Glass EE2 Auto Importer for macOS

Automatically imports photos and videos from a **Google Glass Enterprise Edition 2** to your Mac
as soon as you plug it in over USB, with no Terminal commands needed after setup.

Google has discontinued Glass. Unlike earlier models, EE2 doesn't expose a standard `DCIM` folder,
so a Mac can't see its photos when it's connected. This utility uses Android Debug Bridge (`adb`)
in the background to copy them for you.

- Photos are saved to `~/Pictures/GoogleGlass`
- Videos are saved to `~/Pictures/GoogleGlass/Movies`
- A progress window shows what's being copied, how long is left and where files are going
- Each file's size is verified before it counts as imported
- Imported files are **moved** into a hidden `.imported/` folder on the Glass, **not deleted**,
  so nothing is ever lost

Read the story behind it on the [About page](https://ncubeeight.github.io/GoogleGlassEnterpriseEdition2AutoImporter/).

## What's new in version 2

- **Fixed:** version 1 imported only one photo and one video each time Glass was plugged in.
  Version 2 imports everything in one pass. If you installed version 1, re-run `./install.sh`
  to update.
- **New:** a progress window appears while importing, with a live progress bar, time remaining,
  the destination folders, a *Show in Finder* button and a reminder to keep Glass plugged in
- **New:** notifications when an import finishes, when files fail or when Glass is unplugged mid-import
- **Fixed:** if Glass was unplugged mid-copy, the partial file was never re-imported. It is now
  removed and copied again on the next connection.

## Requirements

- A Mac running macOS 11 or later
- **adb** (Android Debug Bridge). If you don't already have it:
  ```bash
  brew install android-platform-tools
  ```
  An existing Android Studio SDK install is also detected automatically.
- **Xcode Command Line Tools**, used to build the progress window. If the installer can't find a
  Swift compiler, it skips the window and imports still work with notifications only. To install:
  ```bash
  xcode-select --install
  ```
- **USB debugging enabled on the Glass.** Turn on Developer options, then USB debugging, in the
  Glass settings. The first time you connect to a new Mac, accept the
  *Allow USB debugging?* prompt on the Glass display.

## Install

1. Download this repository: use **Code → Download ZIP** on GitHub, download
   [`GlassEE2AutoImport.zip`](GlassEE2AutoImport.zip), or clone it:
   ```bash
   git clone https://github.com/ncubeeight/GoogleGlassEnterpriseEdition2AutoImporter.git
   ```
2. In Terminal, go into the `GlassAutoImport` folder and run the installer:
   ```bash
   cd GoogleGlassEnterpriseEdition2AutoImporter/GlassAutoImport
   ./install.sh
   ```
3. Plug in the Glass. When the progress window appears, your photos and videos are on their way.

The installer works out the right paths for whichever user runs it. It copies everything it needs
into `~/bin` and `~/Library/LaunchAgents`, so the downloaded folder can live anywhere, including
Documents or Desktop. The watcher starts automatically at login.

## Uninstall

```bash
./uninstall.sh
```

This stops the watcher and removes it. Your imported photos and videos are left in place.

## Freeing up space on the Glass

The importer never deletes anything on the Glass. Once you've confirmed everything you care about
is on your Mac, you can clear the archive yourself. **This cannot be undone:**

```bash
adb shell rm -rf /sdcard/Pictures/.imported /sdcard/Movies/.imported
```

## Troubleshooting

The log file is at `~/Library/Logs/glass-import.log`.

| Symptom | What to check |
|---|---|
| `unauthorized` in `adb devices -l` | Accept the *Allow USB debugging?* prompt on the Glass display |
| Nothing happens when Glass is plugged in | Run `adb shell getprop ro.product.model`. It must say `Glass Enterprise Edition 2`, because other Android devices are ignored on purpose |
| No notifications | Allow notifications for **Script Editor** in System Settings → Notifications |
| No progress window | Run `xcode-select --install`, then re-run `./install.sh` |

## How it works

| File | Installed to | Purpose |
|---|---|---|
| `GlassAutoImport/glass-import.sh` | `~/bin/` | Watcher run by launchd. Waits for Glass, finds new files and copies them with `adb pull` |
| `GlassAutoImport/progress/GlassImportProgress.swift` | `~/bin/GlassImportProgress` | Native progress window. Reads the status file the watcher writes to `~/Library/Caches/GlassImporter/status` |
| `GlassAutoImport/com.glassimport.plist.template` | `~/Library/LaunchAgents/com.glassimport.plist` | Starts the watcher at login and keeps it running |

## Credits

Created by Christopher Arnold and built with [Claude Code](https://claude.com/claude-code) by
Anthropic. See [CREDITS.md](CREDITS.md) for details.

This project is not affiliated with or supported by Google or Anthropic.
