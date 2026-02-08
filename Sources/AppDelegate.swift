import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindowController: SettingsWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 메뉴바 아이콘 설정
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "스크롤 반전") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🖱"
            }
        }

        // 메뉴 구성
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "스크롤 반전", action: #selector(toggleScrollReversal), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "설정...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let coffeeItem = NSMenuItem(title: "☕ Buy Me a Coffee", action: #selector(openBuyMeACoffee), keyEquivalent: "")
        coffeeItem.target = self
        menu.addItem(coffeeItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu

        // 설정 창 생성
        settingsWindowController = SettingsWindowController()

        // 상태 변경 알림 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollStateDidChange),
            name: .scrollReversalStateChanged,
            object: nil
        )

        // 저장된 설정에 따라 자동 시작
        if UserDefaults.standard.bool(forKey: "scrollReversalEnabled") {
            let result = ScrollManager.shared.start()
            switch result {
            case .success, .alreadyRunning:
                break
            case .needsAccessibility:
                // 접근성 권한 대기 — 폴링 시작 + 시스템 설정 열기
                ScrollManager.shared.startPermissionPolling()
                openAccessibilitySettings()
            case .eventTapFailed:
                // 이벤트 탭 생성 실패 — 설정 초기화
                UserDefaults.standard.set(false, forKey: "scrollReversalEnabled")
            }
        }
    }

    @objc private func scrollStateDidChange() {
        // 설정 창이 열려 있으면 갱신
        settingsWindowController.loadSettings()
    }

    @objc private func toggleScrollReversal() {
        if ScrollManager.shared.isRunning {
            ScrollManager.shared.stop()
            UserDefaults.standard.set(false, forKey: "scrollReversalEnabled")
        } else {
            let result = ScrollManager.shared.start()
            switch result {
            case .success, .alreadyRunning:
                UserDefaults.standard.set(true, forKey: "scrollReversalEnabled")
            case .needsAccessibility:
                // 접근성 권한 부여 후 자동 시작되도록 폴링
                ScrollManager.shared.startPermissionPolling()
                showAccessibilityAlert()
            case .eventTapFailed:
                showEventTapFailedAlert()
            }
        }
    }

    @objc private func openSettings() {
        settingsWindowController.showWindow()
    }

    @objc private func openBuyMeACoffee() {
        if let url = URL(string: "https://buymeacoffee.com/hulryung") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        ScrollManager.shared.stop()
        NSApp.terminate(nil)
    }

    private func showAccessibilityAlert() {
        // 시스템 설정 > 접근성 열기
        openAccessibilitySettings()

        let alert = NSAlert()
        alert.messageText = "접근성 권한 필요"
        alert.informativeText = "시스템 설정이 열렸습니다.\n\n1. \"mac-mouse-scroll-is-bulpyun\" 항목을 찾아 토글을 켜주세요.\n2. 이미 있지만 꺼져 있다면, 제거 후 다시 추가해주세요.\n3. 목록에 없다면 \"+\" 버튼으로 이 앱을 추가해주세요.\n\n권한을 부여하면 자동으로 활성화됩니다."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "시스템 설정 다시 열기")
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showEventTapFailedAlert() {
        let alert = NSAlert()
        alert.messageText = "스크롤 반전 활성화 실패"
        alert.informativeText = "이벤트 탭 생성에 실패했습니다.\n접근성 권한을 확인하고 앱을 다시 실행해주세요."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // 토글 메뉴 아이템 상태 업데이트
        if let toggleItem = menu.items.first {
            let running = ScrollManager.shared.isRunning
            let polling = ScrollManager.shared.isPollingForPermission
            if polling {
                toggleItem.title = "스크롤 반전: 권한 대기 중..."
                toggleItem.state = .off
            } else {
                toggleItem.title = running ? "스크롤 반전: 켜짐" : "스크롤 반전: 꺼짐"
                toggleItem.state = running ? .on : .off
            }
        }
    }
}
