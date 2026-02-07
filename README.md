# mac-mouse-scroll-is-bulpyun

[한국어](README.ko.md)

A lightweight macOS menu bar app that reverses mouse scroll direction — without affecting your trackpad.

macOS applies "natural scrolling" to both trackpad and mouse. If you prefer natural scrolling on trackpad but traditional scrolling on mouse, this app fixes that.

## Features

- Reverses only mouse scroll direction (trackpad untouched)
- Lives in the menu bar — no Dock icon
- One-click toggle on/off
- Launch at login support (macOS 13+)
- Zero dependencies, pure Swift + AppKit

## Requirements

- macOS 13.0+
- Accessibility permission (prompted on first launch)

## Build

```bash
git clone https://github.com/hulryung/mac-mouse-scroll-is-bulpyun.git
cd mac-mouse-scroll-is-bulpyun
bash build.sh
```

## Run

```bash
open mac-mouse-scroll-is-bulpyun.app
```

On first launch, macOS will ask for Accessibility permission. Grant it in **System Settings > Privacy & Security > Accessibility**.

## Usage

Click the mouse icon in the menu bar to:

- **Toggle scroll reversal** on/off
- Open **Settings** window (with ON/OFF switch and launch at login option)
- **Quit** the app

## How It Works

Uses `CGEventTap` to intercept scroll wheel events. It checks `scrollWheelEventIsContinuous` to distinguish mouse (discrete, value `0`) from trackpad (continuous, value `1`), and only reverses the mouse events.

## License

MIT
