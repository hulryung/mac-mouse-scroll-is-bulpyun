# macOS Mouse Scroll Reverser - Research Findings

## Overview

This document covers the technical research for building a macOS CLI tool that reverses
mouse scroll direction while leaving trackpad scroll direction untouched. The solution
uses the Core Graphics `CGEventTap` API to intercept and modify scroll wheel events.

---

## 1. CGEventTap API

### What is CGEventTap?

`CGEventTap` is a Core Graphics API that allows applications to intercept, observe, and
modify low-level input events (keyboard, mouse, scroll) before they reach their target
application. An "event tap" is inserted into the event processing pipeline.

### Key API: `CGEvent.tapCreate`

```swift
import CoreGraphics

let callback: CGEventTapCallBack = { proxy, type, event, refcon in
    // Process event here
    return Unmanaged.passUnretained(event)
}

let eventMask = (1 << CGEventType.scrollWheel.rawValue)

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,       // Tap at session level
    place: .headInsertEventTap,    // Insert at head (before other taps)
    options: .defaultTap,          // Can modify events (not listen-only)
    eventsOfInterest: CGEventMask(eventMask),
    callback: callback,
    userInfo: nil                  // Optional context pointer
) else {
    fatalError("Failed to create event tap")
}
```

### Parameters Explained

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `tap` | `.cgSessionEventTap` | Intercepts events for the current user session |
| `place` | `.headInsertEventTap` | New tap is inserted before existing taps |
| `options` | `.defaultTap` | Active tap that can modify/filter events |
| `eventsOfInterest` | bitmask with scrollWheel bit | Only intercept scroll wheel events |
| `callback` | `CGEventTapCallBack` | Function called for each matching event |
| `userInfo` | `UnsafeMutableRawPointer?` | Optional context data passed to callback |

### Run Loop Integration

The event tap must be added to a run loop to receive events:

```swift
let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
CFRunLoopRun()  // Blocks and processes events
```

### Handling Tap Timeout

macOS will automatically disable an event tap if the callback takes too long. The
callback receives a `.tapDisabledByTimeout` event type when this happens. The tap must
be re-enabled:

```swift
let callback: CGEventTapCallBack = { proxy, type, event, refcon in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        // Re-enable the tap
        // (Need reference to tap via refcon or global)
        return Unmanaged.passUnretained(event)
    }
    // Normal processing...
    return Unmanaged.passUnretained(event)
}
```

### Callback Signature

```swift
typealias CGEventTapCallBack = @convention(c) (
    CGEventTapProxy,           // Opaque proxy reference
    CGEventType,               // Event type enum
    CGEvent,                   // The event to inspect/modify
    UnsafeMutableRawPointer?   // userInfo from tapCreate
) -> Unmanaged<CGEvent>?       // Return modified event, or nil to drop it
```

---

## 2. Distinguishing Mouse vs Trackpad

### The Key Field: `scrollWheelEventIsContinuous`

The `CGEventField.scrollWheelEventIsContinuous` field (raw value 88) distinguishes
between discrete (mouse) and continuous (trackpad) scroll events:

| Value | Source | Behavior |
|-------|--------|----------|
| **0** | **Mouse** (discrete scroll wheel) | Step-based scrolling, delta is +/-1 per notch |
| **1** | **Trackpad** (continuous touch surface) | Smooth scrolling, variable delta values |

```swift
let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
if isContinuous == 0 {
    // This is a MOUSE scroll event - reverse it
} else {
    // This is a TRACKPAD scroll event - leave it alone
}
```

This is the simplest and most reliable method. Verified to work in Swift via
`CGEvent.getIntegerValueField(.scrollWheelEventIsContinuous)`.

### Alternative Detection Methods

The reference implementation (pilotmoon/Scroll-Reverser) uses a more complex approach:

1. **Passive gesture tap**: Monitors `NSEventMaskGesture` events to track how many
   fingers are touching the trackpad
2. **Touch count check**: If >= 2 fingers are touching within 222ms of a scroll event,
   it is from the trackpad
3. **Fallback**: Uses the `isContinuous` field when gesture data is unavailable

For our simple CLI tool, the `isContinuous` field alone is sufficient.

### Important Note About Magic Mouse

The Magic Mouse has a touch surface but generates **continuous** scroll events
(isContinuous = 1). This means with the `isContinuous` check alone, Magic Mouse scrolls
will NOT be reversed. This is actually correct behavior for most users since Magic Mouse
uses the same "natural scrolling" gesture as trackpads. If separate Magic Mouse handling
is needed, the gesture-monitoring approach from Scroll-Reverser would be required.

---

## 3. Scroll Event Delta Fields

### Available Fields

There are three sets of delta fields, each on two axes:

| Field | Type | Description |
|-------|------|-------------|
| `scrollWheelEventDeltaAxis1` (11) | Integer | Raw delta, no acceleration. Axis1 = vertical |
| `scrollWheelEventDeltaAxis2` (12) | Integer | Raw delta, no acceleration. Axis2 = horizontal |
| `scrollWheelEventPointDeltaAxis1` (96) | Integer | Pixel delta with acceleration |
| `scrollWheelEventPointDeltaAxis2` (97) | Integer | Pixel delta with acceleration |
| `scrollWheelEventFixedPtDeltaAxis1` (93) | Double | Fixed-point delta with acceleration |
| `scrollWheelEventFixedPtDeltaAxis2` (94) | Double | Fixed-point delta with acceleration |

### Which Fields to Negate

**All six fields** should be negated for correct reversal. From the pilotmoon
Scroll-Reverser source: setting `DeltaAxis` causes macOS to internally modify
`PointDeltaAxis` (8x multiplier on DeltaAxis value). However, to avoid platform-specific
quirks, it is safest to negate all fields explicitly:

```swift
// Negate all delta fields for both axes
// Integer fields
let d1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
let d2 = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -d1)
event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -d2)

// Point delta fields (pixel-based, accelerated)
let pd1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
let pd2 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pd1)
event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -pd2)

// Fixed-point delta fields
let fpd1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
let fpd2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fpd1)
event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fpd2)
```

### Note on Vertical-Only Reversal

For a typical "reverse mouse scroll" use case, you may only want to negate Axis1
(vertical). Axis2 (horizontal) reversal is optional and depends on user preference.
Most users only want vertical scrolling reversed.

---

## 4. Permissions

### Required Permission: Accessibility (or Input Monitoring)

CGEventTap with `.defaultTap` (active/modifying) requires **Accessibility** permission.
The user must grant this in:

**System Settings > Privacy & Security > Accessibility**

### Checking Permissions

```swift
import ApplicationServices

// Simple check (no prompt)
let trusted = AXIsProcessTrusted()

// Check with prompt to open System Settings
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
let trustedWithPrompt = AXIsProcessTrustedWithOptions(options)
```

### Alternative: Input Monitoring APIs

For event taps specifically, there are newer APIs:

```swift
import CoreGraphics

// Check without prompting
let canListen = CGPreflightListenEventAccess()

// Request permission (shows system dialog)
let granted = CGRequestListenEventAccess()

// For posting/modifying events:
let canPost = CGPreflightPostEventAccess()
let postGranted = CGRequestPostEventAccess()
```

### Practical Approach for CLI Tool

For a CLI tool, the simplest approach is:

```swift
if !AXIsProcessTrusted() {
    print("Accessibility permission required.")
    print("Grant permission in: System Settings > Privacy & Security > Accessibility")
    print("Add Terminal.app (or your terminal emulator) to the list.")
    exit(1)
}
```

**Important**: When running as a CLI tool from Terminal, the **Terminal.app** (or iTerm2,
etc.) itself needs Accessibility permission, not the compiled binary.

---

## 5. CLI App Structure

### Minimal Swift CLI App

A complete scroll reverser can be implemented as a single Swift file:

```swift
import CoreGraphics
import ApplicationServices

// 1. Check permissions
guard AXIsProcessTrusted() else {
    fputs("Error: Accessibility permission required.\n", stderr)
    fputs("Grant in: System Settings > Privacy & Security > Accessibility\n", stderr)
    exit(1)
}

// 2. Define callback
let callback: CGEventTapCallBack = { proxy, type, event, refcon in
    if type == .tapDisabledByTimeout {
        // Re-enable tap (need global reference)
        return Unmanaged.passUnretained(event)
    }

    guard type == .scrollWheel else {
        return Unmanaged.passUnretained(event)
    }

    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if isContinuous == 0 {
        // Mouse scroll - reverse vertical direction
        let d1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -d1)
        // ... negate other fields too
    }

    return Unmanaged.passUnretained(event)
}

// 3. Create event tap
let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: mask,
    callback: callback,
    userInfo: nil
) else {
    fputs("Failed to create event tap.\n", stderr)
    exit(1)
}

// 4. Add to run loop and run
let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

// 5. Handle signals for clean shutdown
signal(SIGINT) { _ in exit(0) }
signal(SIGTERM) { _ in exit(0) }

print("Mouse scroll reverser is running. Press Ctrl+C to stop.")
CFRunLoopRun()
```

### Compilation

```bash
swiftc -O -o scroll-reverser main.swift
```

### Running as Background Process

```bash
./scroll-reverser &
# Or use launchd for auto-start on login
```

---

## 6. Verified API Details (Tested on macOS)

All the following APIs have been verified to compile and work correctly:

| API | Framework | Status |
|-----|-----------|--------|
| `CGEvent.tapCreate(tap:place:options:eventsOfInterest:callback:userInfo:)` | CoreGraphics | Verified |
| `CGEventTapCallBack` type alias | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventIsContinuous` (raw: 88) | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventDeltaAxis1` (raw: 11) | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventDeltaAxis2` (raw: 12) | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventPointDeltaAxis1` (raw: 96) | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventPointDeltaAxis2` (raw: 97) | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventFixedPtDeltaAxis1` (raw: 93) | CoreGraphics | Verified |
| `CGEventField.scrollWheelEventFixedPtDeltaAxis2` (raw: 94) | CoreGraphics | Verified |
| `CGEventType.scrollWheel` (raw: 22) | CoreGraphics | Verified |
| `CGEventType.tapDisabledByTimeout` | CoreGraphics | Verified |
| `AXIsProcessTrusted()` | ApplicationServices | Verified |
| `CGPreflightListenEventAccess()` | CoreGraphics | Verified |
| `CFMachPortCreateRunLoopSource` | CoreFoundation | Verified |
| `CFRunLoopAddSource` / `CFRunLoopRun` | CoreFoundation | Verified |

---

## 7. References

- [pilotmoon/Scroll-Reverser](https://github.com/pilotmoon/Scroll-Reverser) - Reference
  implementation (Objective-C) with advanced mouse/trackpad detection
- [MouseTap.m source](https://github.com/pilotmoon/Scroll-Reverser/blob/master/MouseTap.m) -
  Core event tap implementation
- [Low-level scroll events on macOS](https://gist.github.com/svoisen/5215826) - Detailed
  analysis of scroll wheel event fields
- [CGEventField.scrollWheelEventDeltaAxis1 docs](https://developer.apple.com/documentation/coregraphics/cgeventfield/scrollwheeleventdeltaaxis1) -
  Apple documentation
- [Detecting trackpad vs Magic Mouse scroll](https://blog.rectorsquid.com/detecting-trackpad-scroll-vs-magic-mouse-scroll/) -
  Alternative detection approach via touch events
