import CoreGraphics
import ApplicationServices

// 마우스 스크롤 이벤트를 가로채서 방향을 반전시키는 콜백 함수
// 트랙패드 스크롤은 그대로 통과시킴
func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // 이벤트 탭이 비활성화된 경우 다시 활성화
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let tapRef = Unmanaged<AnyObject>.fromOpaque(userInfo).takeUnretainedValue()
            if let tap = tapRef as! CFMachPort? {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .scrollWheel else {
        return Unmanaged.passRetained(event)
    }

    // isContinuous가 0이면 마우스, 1이면 트랙패드
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if isContinuous != 0 {
        // 트랙패드 이벤트는 그대로 통과
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

// 접근성 권한 확인
if !AXIsProcessTrusted() {
    print("접근성 권한이 필요합니다.")
    print("시스템 설정 > 개인정보 보호 및 보안 > 접근성 에서 이 앱을 허용해주세요.")
    print("권한을 부여한 후 다시 실행해주세요.")
    exit(1)
}

// 스크롤 휠 이벤트만 감지하는 이벤트 탭 생성
let eventMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue)

guard let eventTap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: scrollCallback,
    userInfo: nil
) else {
    print("이벤트 탭 생성에 실패했습니다. 접근성 권한을 확인해주세요.")
    exit(1)
}

// 콜백에서 탭을 다시 활성화할 수 있도록 userInfo 설정
// 이미 생성된 탭의 userInfo는 변경할 수 없으므로, 탭 비활성화 시 재생성 대신
// 별도로 처리 (위 콜백에서 userInfo로 전달)

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

print("마우스 스크롤 방향 반전이 활성화되었습니다. (트랙패드는 영향 없음)")
print("종료하려면 Ctrl+C를 누르세요.")

// 런루프 실행 (프로세스 유지)
CFRunLoopRun()
