# mac-mouse-scroll-is-bulpyun

> **⚠️ This project is no longer actively maintained.**
> I recommend using [**Mos**](https://mos.caldis.me/) instead — it's a fantastic open-source app that does the same thing and much more. Shoutout to the Mos team!

[한국어](README.ko.md)

A lightweight macOS menu bar app that reverses mouse scroll direction — without affecting your trackpad.

macOS applies "natural scrolling" to both trackpad and mouse. If you prefer natural scrolling on trackpad but traditional scrolling on mouse, this app fixes that.

## Install

### Homebrew (Recommended)

```bash
brew install --cask hulryung/tap/mac-mouse-scroll-is-bulpyun
```

### Manual

Download the latest `.dmg` from [Releases](https://github.com/hulryung/mac-mouse-scroll-is-bulpyun/releases), open it, and drag the app to `/Applications`.

### Build from Source

```bash
git clone https://github.com/hulryung/mac-mouse-scroll-is-bulpyun.git
cd mac-mouse-scroll-is-bulpyun
bash build.sh
open mac-mouse-scroll-is-bulpyun.app
```

## Features

- Reverses only mouse scroll direction (trackpad untouched)
- Lives in the menu bar — no Dock icon
- One-click toggle on/off
- Auto-activates after granting Accessibility permission
- Launch at login support (macOS 13+)
- Zero dependencies, pure Swift + AppKit

## Requirements

- macOS 13.0+
- Accessibility permission (prompted on first launch)

## Usage

Click the mouse icon in the menu bar to:

- **Toggle scroll reversal** on/off
- Open **Settings** window (with ON/OFF switch and launch at login option)
- **Quit** the app

On first launch, the app will open System Settings for you. Grant Accessibility permission in **System Settings > Privacy & Security > Accessibility**, and scroll reversal activates automatically.

> **Note:** If you rebuild from source, macOS treats the new binary as a different app. You may need to remove the old entry and re-grant Accessibility permission.

## How It Works

Uses `CGEventTap` at the HID level to intercept scroll wheel events. It checks `scrollWheelEventIsContinuous` to distinguish mouse (discrete, `0`) from trackpad (continuous, `1`). For mouse events, it creates a new `CGEvent` with reversed delta values, bypassing the original IOHIDEvent that macOS would otherwise use to determine scroll direction.

## Support

If you find this app useful, consider supporting the project:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/hulryung)

## License

MIT
