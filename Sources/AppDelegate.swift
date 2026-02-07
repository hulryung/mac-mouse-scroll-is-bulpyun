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

        // 저장된 설정에 따라 자동 시작
        if UserDefaults.standard.bool(forKey: "scrollReversalEnabled") {
            _ = ScrollManager.shared.start()
        }
    }

    @objc private func toggleScrollReversal() {
        if ScrollManager.shared.isRunning {
            ScrollManager.shared.stop()
            UserDefaults.standard.set(false, forKey: "scrollReversalEnabled")
        } else {
            let success = ScrollManager.shared.start()
            if success {
                UserDefaults.standard.set(true, forKey: "scrollReversalEnabled")
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
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // 토글 메뉴 아이템 상태 업데이트
        if let toggleItem = menu.items.first {
            let running = ScrollManager.shared.isRunning
            toggleItem.title = running ? "스크롤 반전: 켜짐" : "스크롤 반전: 꺼짐"
            toggleItem.state = running ? .on : .off
        }
    }
}
