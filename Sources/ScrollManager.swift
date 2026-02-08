import CoreGraphics
import ApplicationServices
import Foundation

/// start() 결과를 구분하기 위한 enum
enum StartResult {
    case success
    case alreadyRunning
    case needsAccessibility
    case eventTapFailed
}

/// 상태 변경 알림 이름
extension Notification.Name {
    static let scrollReversalStateChanged = Notification.Name("scrollReversalStateChanged")
}

/// 마우스 스크롤 방향을 반전시키는 매니저 (트랙패드는 영향 없음)
class ScrollManager {
    static let shared = ScrollManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    private(set) var isRunning = false

    private init() {}

    func start() -> StartResult {
        guard !isRunning else { return .alreadyRunning }

        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return .needsAccessibility
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
            return .eventTapFailed
        }

        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        stopPermissionPolling()
        NotificationCenter.default.post(name: .scrollReversalStateChanged, object: nil)
        return .success
    }

    func stop() {
        stopPermissionPolling()
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
        NotificationCenter.default.post(name: .scrollReversalStateChanged, object: nil)
    }

    func startPermissionPolling() {
        stopPermissionPolling()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.permissionTimer = nil
                let result = self?.start() ?? .eventTapFailed
                if result == .success {
                    UserDefaults.standard.set(true, forKey: "scrollReversalEnabled")
                }
            }
        }
    }

    func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    var isPollingForPermission: Bool {
        return permissionTimer != nil
    }
}

// MARK: - Event Tap Callback

private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        ScrollManager.shared.reEnableTap()
        return Unmanaged.passUnretained(event)
    }

    guard type == .scrollWheel else {
        return Unmanaged.passUnretained(event)
    }

    // isContinuous: 0 = 마우스, 1 = 트랙패드
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if isContinuous != 0 {
        return Unmanaged.passUnretained(event)
    }

    // 원본 델타 읽기
    let delta1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    let delta2 = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)

    // IOHIDEvent가 없는 새 스크롤 이벤트 생성 (반전된 값)
    guard let newEvent = CGEvent(
        scrollWheelEvent2Source: CGEventSource(event: event),
        units: .line,
        wheelCount: 2,
        wheel1: Int32(-delta1),
        wheel2: Int32(-delta2),
        wheel3: 0
    ) else {
        return Unmanaged.passUnretained(event)
    }

    return Unmanaged.passRetained(newEvent)
}

extension ScrollManager {
    fileprivate func reEnableTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}
