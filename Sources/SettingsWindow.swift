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
        let enabled = UserDefaults.standard.bool(forKey: "scrollReversalEnabled")
        scrollToggle.state = enabled ? .on : .off
        statusLabel.stringValue = enabled ? "켜짐" : "꺼짐"

        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            loginToggle.state = (status == .enabled) ? .on : .off
        } else {
            loginToggle.isHidden = true
        }
    }

    @objc private func scrollToggleChanged(_ sender: NSSwitch) {
        let enabled = sender.state == .on
        UserDefaults.standard.set(enabled, forKey: "scrollReversalEnabled")
        statusLabel.stringValue = enabled ? "켜짐" : "꺼짐"

        if enabled {
            let success = ScrollManager.shared.start()
            if !success {
                // 접근성 권한이 없는 경우 토글 되돌리기
                sender.state = .off
                statusLabel.stringValue = "꺼짐"
                UserDefaults.standard.set(false, forKey: "scrollReversalEnabled")
            }
        } else {
            ScrollManager.shared.stop()
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
}
