import CoreGraphics
import ApplicationServices

/// 마우스 스크롤 방향을 반전시키는 매니저 (트랙패드는 영향 없음)
class ScrollManager {
    static let shared = ScrollManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false

    private init() {}

    func start() -> Bool {
        guard !isRunning else { return true }

        if !AXIsProcessTrusted() {
            // 접근성 권한 요청 다이얼로그 표시
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return false
        }

        let eventMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: scrollCallback,
            userInfo: nil
        ) else {
            return false
        }

        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        return true
    }

    func stop() {
        guard isRunning else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            CFMachPortInvalidate(tap)
        }

        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }
}

private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        // 이벤트 탭이 비활성화된 경우, ScrollManager를 통해 재활성화
        ScrollManager.shared.reEnableTap()
        return Unmanaged.passRetained(event)
    }

    guard type == .scrollWheel else {
        return Unmanaged.passRetained(event)
    }

    // isContinuous가 0이면 마우스, 1이면 트랙패드
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if isContinuous != 0 {
        return Unmanaged.passRetained(event)
    }

    // 마우스 스크롤 방향 반전 (세로축)
    let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta)

    let pointDelta = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
    event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointDelta)

    let fixedPtDelta = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
    event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedPtDelta)

    return Unmanaged.passRetained(event)
}

extension ScrollManager {
    fileprivate func reEnableTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}
