
import AppKit

// @MainActor：讓 AppKit UI 操作在主執行環境執行
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // 儲存桌面寵物視窗
    private var window: NSWindow?

    // 儲存 macOS 選單列項目
    private var statusItem: NSStatusItem?

    // 儲存三個需要動態更新的選單項目
    private var normalItem: NSMenuItem?
    private var focusItem: NSMenuItem?
    private var visibilityItem: NSMenuItem?

    // 記錄目前是否處於 Focus Mode
    private var isFocusMode = true

    // App 啟動完成後，由系統呼叫
    func applicationDidFinishLaunching(_ notification: Notification) {

        // 建立桌面寵物視窗
        createPetWindow()

        // 建立右上角選單列控制器
        createStatusMenu()
    }

    // MARK: - Desktop Pet Window

    // 建立透明桌面寵物視窗
    private func createPetWindow() {

        // 建立一個 260 × 320 的無邊框視窗
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 視窗背景透明
        window.isOpaque = false
        window.backgroundColor = .clear

        // 移除視窗陰影
        window.hasShadow = false

        // 浮在一般應用程式上方
        window.level = .floating

        // 預設為 Focus Mode，滑鼠可穿透
        window.ignoresMouseEvents = true

        // 建立視窗內容區域
        let contentView = NSView(
            frame: NSRect(x: 0, y: 0, width: 260, height: 320)
        )

        // 啟用圖層並設定透明背景
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        // 建立圖片顯示元件
        let imageView = NSImageView(frame: contentView.bounds)

        // 維持原始圖片比例
        imageView.imageScaling = .scaleProportionallyUpOrDown

        // 將圖片放在顯示區域中央
        imageView.imageAlignment = .alignCenter

        // 移除圖片框線
        imageView.imageFrameStyle = .none

        // 讓圖片區域跟隨視窗大小改變
        imageView.autoresizingMask = [.width, .height]

        // 從 Swift Package 的資源 Bundle 載入 pet.png
        if let imageURL = Bundle.module.url(
            forResource: "pet",
            withExtension: "png"
        ),
        let image = NSImage(contentsOf: imageURL) {

            // 成功讀取圖片
            imageView.image = image

        } else {

            // 圖片載入失敗時，使用系統圖示
            imageView.image = NSImage(
                systemSymbolName: "cat.fill",
                accessibilityDescription: "Desktop Pet"
            )

            imageView.contentTintColor = .systemPink
            print("找不到 pet.png")
        }

        // 將圖片加入視窗內容
        contentView.addSubview(imageView)
        window.contentView = contentView

        // 將角色放在主要螢幕右下角
        if let screen = NSScreen.main {
            let area = screen.visibleFrame

            let x = area.maxX - window.frame.width - 24
            let y = area.minY + 24

            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // 顯示視窗，不主動搶走鍵盤焦點
        window.orderFrontRegardless()

        // 保存視窗物件
        self.window = window
    }

    // MARK: - Menu Bar Controller

    // 建立 macOS 右上角選單
    private func createStatusMenu() {

        // 建立選單列項目，寬度為標準正方形
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        // 保留物件參照，避免圖示消失
        self.statusItem = item

        // 設定選單列按鈕圖示
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "pawprint.fill",
                accessibilityDescription: "Desktop Pet"
            )
        }

        // 建立選單
        let menu = NSMenu()

        // Normal Mode 選項
        let normal = NSMenuItem(
            title: "Normal Mode - 可互動",
            action: #selector(enableNormalMode(_:)),
            keyEquivalent: ""
        )

        // 設定選項的事件處理物件
        normal.target = self

        // 將選項加入選單
        menu.addItem(normal)
        self.normalItem = normal

        // Focus Mode 選項
        let focus = NSMenuItem(
            title: "Focus Mode - 點擊穿透",
            action: #selector(enableFocusMode(_:)),
            keyEquivalent: ""
        )

        focus.target = self
        menu.addItem(focus)
        self.focusItem = focus

        // 加入分隔線
        menu.addItem(NSMenuItem.separator())

        // 顯示或隱藏角色
        let visibility = NSMenuItem(
            title: "Hide Pet",
            action: #selector(togglePetVisibility(_:)),
            keyEquivalent: ""
        )

        visibility.target = self
        menu.addItem(visibility)
        self.visibilityItem = visibility

        // 再加入分隔線
        menu.addItem(NSMenuItem.separator())

        // 離開 App
        let quit = NSMenuItem(
            title: "Quit Desktop Pet",
            action: #selector(quitApp(_:)),
            keyEquivalent: ""
        )

        quit.target = self
        menu.addItem(quit)

        // 初始化選單的勾選狀態與文字
        updateMenuState()

        // 將整個選單指定給選單列圖示
        item.menu = menu
    }

    // MARK: - Menu Actions

    // 切換成 Normal Mode
    @objc private func enableNormalMode(_ sender: NSMenuItem) {

        // 記錄目前模式
        isFocusMode = false

        // 關閉點擊穿透，讓視窗可以接收滑鼠事件
        window?.ignoresMouseEvents = false

        // 更新選單狀態
        updateMenuState()
    }

    // 切換成 Focus Mode
    @objc private func enableFocusMode(_ sender: NSMenuItem) {

        // 記錄目前模式
        isFocusMode = true

        // 開啟點擊穿透
        window?.ignoresMouseEvents = true

        // 更新選單狀態
        updateMenuState()
    }

    // 顯示或隱藏桌面寵物
    @objc private func togglePetVisibility(_ sender: NSMenuItem) {

        // 確認視窗存在
        guard let window = window else { return }

        // 如果角色目前可見，就隱藏
        if window.isVisible {
            window.orderOut(nil)
        } else {

            // 否則重新顯示角色
            window.orderFrontRegardless()
        }

        // 更新選單文字
        updateMenuState()
    }

    // 結束 Desktop Pet
    @objc private func quitApp(_ sender: NSMenuItem) {

        // 要求 NSApplication 正常結束程式
        NSApp.terminate(nil)
    }

    // MARK: - Menu State

    // 更新選單項目的狀態
    private func updateMenuState() {

        // 在目前啟用的模式旁顯示勾選記號
        normalItem?.state = isFocusMode ? .off : .on
        focusItem?.state = isFocusMode ? .on : .off

        // 根據角色是否可見，調整選單文字
        if window?.isVisible == true {
            visibilityItem?.title = "Hide Pet"
        } else {
            visibilityItem?.title = "Show Pet"
        }
    }
}


// MARK: - Application Entry Point

// 指定程式的進入點
@main
struct DesktopPet {

    // 在主執行環境啟動 App
    @MainActor
    static func main() {

        // 取得目前的 macOS 應用程式物件
        let app = NSApplication.shared

        // 建立生命週期代理物件
        let delegate = AppDelegate()

        // 指定 AppDelegate
        app.delegate = delegate

        // 設定為輔助型 App，不顯示 Dock 圖示
        app.setActivationPolicy(.accessory)

        // 啟動事件循環，並確保代理物件持續存在
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
