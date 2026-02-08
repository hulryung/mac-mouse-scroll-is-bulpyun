import AppKit
import ServiceManagement

class SettingsWindowController: NSWindowController {
    private var scrollToggle: NSSwitch!
    private var statusLabel: NSTextField!
    private var loginToggle: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "mac-mouse-scroll-is-bulpyun"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupUI()
        loadSettings()

        // 상태 변경 알림 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollStateDidChange),
            name: .scrollReversalStateChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let containerView = NSView(frame: contentView.bounds)
        containerView.autoresizingMask = [.width, .height]
        contentView.addSubview(containerView)

        // 스크롤 반전 ON/OFF 섹션
        let scrollLabel = NSTextField(labelWithString: "스크롤 반전")
        scrollLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        scrollLabel.frame = NSRect(x: 20, y: 110, width: 120, height: 20)
        containerView.addSubview(scrollLabel)

        statusLabel = NSTextField(labelWithString: "꺼짐")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 145, y: 110, width: 60, height: 20)
        containerView.addSubview(statusLabel)

        scrollToggle = NSSwitch()
        scrollToggle.frame = NSRect(x: 230, y: 108, width: 50, height: 24)
        scrollToggle.target = self
        scrollToggle.action = #selector(scrollToggleChanged)
        containerView.addSubview(scrollToggle)

        // 구분선
        let separator = NSBox()
        separator.boxType = .separator
        separator.frame = NSRect(x: 20, y: 90, width: 260, height: 1)
        containerView.addSubview(separator)

        // 로그인 시 자동 시작
        loginToggle = NSButton(checkboxWithTitle: "로그인 시 자동 시작", target: self, action: #selector(loginToggleChanged))
        loginToggle.font = NSFont.systemFont(ofSize: 13)
        loginToggle.frame = NSRect(x: 18, y: 55, width: 260, height: 20)
        containerView.addSubview(loginToggle)

        // 안내 문구
        let infoLabel = NSTextField(labelWithString: "마우스 스크롤 방향만 반전합니다.\n트랙패드는 영향 없습니다.")
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = .tertiaryLabelColor
        infoLabel.maximumNumberOfLines = 2
        infoLabel.frame = NSRect(x: 20, y: 10, width: 260, height: 35)
        containerView.addSubview(infoLabel)
    }

    func loadSettings() {
        // 실제 ScrollManager 상태를 반영 (UserDefaults가 아닌 실제 동작 상태)
        let running = ScrollManager.shared.isRunning
        scrollToggle.state = running ? .on : .off
        statusLabel.stringValue = running ? "켜짐" : "꺼짐"

        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            loginToggle.state = (status == .enabled) ? .on : .off
        } else {
            loginToggle.isHidden = true
        }
    }

    @objc private func scrollStateDidChange() {
        loadSettings()
    }

    @objc private func scrollToggleChanged(_ sender: NSSwitch) {
        let enabled = sender.state == .on

        if enabled {
            let result = ScrollManager.shared.start()
            switch result {
            case .success, .alreadyRunning:
                UserDefaults.standard.set(true, forKey: "scrollReversalEnabled")
                statusLabel.stringValue = "켜짐"
            case .needsAccessibility:
                // 접근성 권한 부여 후 자동 시작되도록 폴링
                ScrollManager.shared.startPermissionPolling()
                sender.state = .off
                statusLabel.stringValue = "권한 대기 중..."
                showAccessibilityGuide()
            case .eventTapFailed:
                sender.state = .off
                statusLabel.stringValue = "꺼짐"
                UserDefaults.standard.set(false, forKey: "scrollReversalEnabled")
                showEventTapError()
            }
        } else {
            ScrollManager.shared.stop()
            UserDefaults.standard.set(false, forKey: "scrollReversalEnabled")
            statusLabel.stringValue = "꺼짐"
        }
    }

    @objc private func loginToggleChanged(_ sender: NSButton) {
        if #available(macOS 13.0, *) {
            do {
                if sender.state == .on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // 실패 시 토글 되돌리기
                sender.state = sender.state == .on ? .off : .on
                let alert = NSAlert()
                alert.messageText = "로그인 항목 설정 실패"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    func showWindow() {
        loadSettings()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showAccessibilityGuide() {
        // 시스템 설정 > 접근성 열기
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        let alert = NSAlert()
        alert.messageText = "접근성 권한 필요"
        alert.informativeText = "시스템 설정이 열렸습니다.\n\n1. \"mac-mouse-scroll-is-bulpyun\" 항목을 찾아 토글을 켜주세요.\n2. 이미 있지만 꺼져 있다면, 제거 후 다시 추가해주세요.\n3. 목록에 없다면 \"+\" 버튼으로 이 앱을 추가해주세요.\n\n권한을 부여하면 자동으로 활성화됩니다."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }

    private func showEventTapError() {
        let alert = NSAlert()
        alert.messageText = "스크롤 반전 활성화 실패"
        alert.informativeText = "이벤트 탭 생성에 실패했습니다.\n접근성 권한을 확인하고 앱을 다시 실행해주세요."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }
}
