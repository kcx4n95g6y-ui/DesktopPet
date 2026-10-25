
import AppKit

// MARK: - Draggable Image View

// 自訂 NSImageView，讓角色圖片可以拖曳整個視窗
@MainActor
final class DraggablePetImageView: NSImageView {

    // 使用者按下滑鼠左鍵時，AppKit 會呼叫此方法
    override func mouseDown(with event: NSEvent) {

        // 將滑鼠按下事件交給視窗，開始拖曳視窗
        window?.performDrag(with: event)
    }
}


// MARK: - App Delegate

// NSWindowDelegate 用來接收視窗移動等事件
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // 儲存桌面寵物視窗
    private var window: NSWindow?

    // 儲存選單列圖示
    private var statusItem: NSStatusItem?

    // 儲存需要更新狀態的選單項目
    private var normalItem: NSMenuItem?
    private var focusItem: NSMenuItem?
    private var visibilityItem: NSMenuItem?

    // 預設使用 Focus Mode
    private var isFocusMode = true

    // UserDefaults 使用的儲存鍵
    private let positionXKey = "pet.positionX"
    private let positionYKey = "pet.positionY"
    private let sizeKey = "pet.width"

    // App 啟動完成後執行
    func applicationDidFinishLaunching(_ notification: Notification) {

        // 建立桌面寵物視窗
        createPetWindow()

        // 建立 macOS 選單列
        createStatusMenu()
    }


    // MARK: - Pet Window

    // 建立透明桌面寵物視窗
    private func createPetWindow() {

        // 讀取上次儲存的角色寬度
        let savedWidth = UserDefaults.standard.double(forKey: sizeKey)

        // 有有效的儲存值就使用，否則預設為 260
        let width: CGFloat =
            savedWidth.isFinite && (160...400).contains(savedWidth)
            ? CGFloat(savedWidth)
            : 260

        // 依照原本 260 × 320 的比例計算高度
        let height = width * 320.0 / 260.0

        // 建立無邊框視窗
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 設定透明背景
        window.isOpaque = false
        window.backgroundColor = .clear

        // 移除視窗陰影
        window.hasShadow = false

        // 讓視窗浮在一般 App 上方
        window.level = .floating

        // 允許使用者移動視窗
        window.isMovable = true

        // Focus Mode 預設開啟點擊穿透
        window.ignoresMouseEvents = isFocusMode

        // 建立透明內容區域
        let contentView = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        // 啟用 Core Animation 圖層
        contentView.wantsLayer = true

        // 設定內容區域透明
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        // 使用我們自己定義的可拖曳 ImageView
        let imageView = DraggablePetImageView(
            frame: contentView.bounds
        )

        // 保持圖片比例
        imageView.imageScaling = .scaleProportionallyUpOrDown

        // 將圖片置中
        imageView.imageAlignment = .alignCenter

        // 不顯示圖片外框
        imageView.imageFrameStyle = .none

        // 視窗尺寸改變時，自動調整圖片區域
        imageView.autoresizingMask = [.width, .height]

        // 從資源 Bundle 載入角色圖片
        if let imageURL = Bundle.module.url(
            forResource: "pet",
            withExtension: "png"
        ),
        let image = NSImage(contentsOf: imageURL) {

            // 圖片讀取成功
            imageView.image = image

        } else {

            // 圖片讀取失敗時顯示備用圖示
            imageView.image = NSImage(
                systemSymbolName: "cat.fill",
                accessibilityDescription: "Desktop Pet"
            )

            // 備用圖示顏色
            imageView.contentTintColor = .systemPink
        }

        // 將圖片加入內容區域
        contentView.addSubview(imageView)

        // 將內容區域放入視窗
        window.contentView = contentView

        // 還原上次儲存的位置
        restorePetPosition(window)

        // 保存視窗參照
        self.window = window

        // 指定視窗代理，用來監聽移動事件
        window.delegate = self

        // 顯示視窗
        window.orderFrontRegardless()
    }


    // MARK: - Window Position

    // 還原角色位置
    private func restorePetPosition(_ window: NSWindow) {

        // 取得本機設定儲存區
        let defaults = UserDefaults.standard

        // 確認之前有儲存 X、Y 座標
        if defaults.object(forKey: positionXKey) != nil,
           defaults.object(forKey: positionYKey) != nil {

            // 讀取之前的座標
            let x = defaults.double(forKey: positionXKey)
            let y = defaults.double(forKey: positionYKey)

            // 建立儲存位置對應的視窗矩形
            let savedFrame = NSRect(
                x: x,
                y: y,
                width: window.frame.width,
                height: window.frame.height
            )

            // 確認視窗仍有至少 80 × 80 的區域在螢幕上
            let isOnScreen = NSScreen.screens.contains { screen in
                let visible = screen.visibleFrame.intersection(savedFrame)

                return visible.width >= 80 && visible.height >= 80
            }

            // 若座標有效，而且視窗沒有跑到螢幕外
            if x.isFinite && y.isFinite && isOnScreen {

                // 使用之前儲存的位置
                window.setFrameOrigin(NSPoint(x: x, y: y))
                return
            }
        }

        // 沒有有效紀錄時，使用預設右下角位置
        if let screen = NSScreen.main {

            // 取得主要螢幕的可用範圍
            let area = screen.visibleFrame

            // 計算右下角位置
            let x = area.maxX - window.frame.width - 24
            let y = area.minY + 24

            // 移動視窗
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    // 當視窗位置改變時，系統會呼叫此方法
    func windowDidMove(_ notification: Notification) {

        // 儲存最新的位置
        savePetPosition()
    }

    // 將角色座標保存到 UserDefaults
    private func savePetPosition() {

        // 確認視窗存在
        guard let window = window else { return }

        // 讀取視窗左下角的 X、Y 座標
        let x = Double(window.frame.minX)
        let y = Double(window.frame.minY)

        // 儲存到本機
        UserDefaults.standard.set(x, forKey: positionXKey)
        UserDefaults.standard.set(y, forKey: positionYKey)
    }


    // MARK: - Pet Size

    // 根據倍率調整角色尺寸
    private func resizePet(scale: CGFloat) {

        // 確認視窗存在
        guard let window = window else { return }

        // 記錄調整前的視窗大小和位置
        let oldFrame = window.frame

        // 乘上縮放倍率，並限制寬度為 160～400
        let newWidth = min(
            max((oldFrame.width * scale).rounded(), 160),
            400
        )

        // 如果已經到達尺寸限制，就不繼續調整
        if newWidth == oldFrame.width { return }

        // 維持原本圖片顯示比例
        let newHeight = newWidth * 320.0 / 260.0

        // 保持右邊緣的位置，避免縮放後偏移太多
        var newX = oldFrame.maxX - newWidth

        // 保持底部位置
        var newY = oldFrame.minY

        // 防止縮放後超出目前螢幕的可用範圍
        if let screen = window.screen ?? NSScreen.main {
            let area = screen.visibleFrame

            newX = max(
                area.minX,
                min(newX, area.maxX - newWidth)
            )

            newY = max(
                area.minY,
                min(newY, area.maxY - newHeight)
            )
        }

        // 建立新的視窗矩形
        let newFrame = NSRect(
            x: newX,
            y: newY,
            width: newWidth,
            height: newHeight
        )

        // 將新尺寸套用到視窗
        window.setFrame(newFrame, display: true)

        // 記住新的角色寬度
        UserDefaults.standard.set(
            Double(newWidth),
            forKey: sizeKey
        )

        // 同時儲存調整後的位置
        savePetPosition()
    }


    // MARK: - Menu Bar

    // 建立選單列控制器
    private func createStatusMenu() {

        // 在 macOS 右上角建立選單列項目
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        // 保存選單列物件
        statusItem = item

        // 設定腳掌圖示
        item.button?.image = NSImage(
            systemSymbolName: "pawprint.fill",
            accessibilityDescription: "Desktop Pet"
        )

        // 建立選單
        let menu = NSMenu()

        // Normal Mode
        let normal = NSMenuItem(
            title: "Normal Mode - Draggable",
            action: #selector(enableNormalMode(_:)),
            keyEquivalent: ""
        )

        // 設定點擊事件接收者
        normal.target = self
        menu.addItem(normal)
        normalItem = normal

        // Focus Mode
        let focus = NSMenuItem(
            title: "Focus Mode - Click Through",
            action: #selector(enableFocusMode(_:)),
            keyEquivalent: ""
        )

        focus.target = self
        menu.addItem(focus)
        focusItem = focus

        // 分隔線
        menu.addItem(.separator())

        // 縮小角色
        let smaller = NSMenuItem(
            title: "Smaller Pet",
            action: #selector(makePetSmaller(_:)),
            keyEquivalent: ""
        )

        smaller.target = self
        menu.addItem(smaller)

        // 放大角色
        let larger = NSMenuItem(
            title: "Larger Pet",
            action: #selector(makePetLarger(_:)),
            keyEquivalent: ""
        )

        larger.target = self
        menu.addItem(larger)

        // 分隔線
        menu.addItem(.separator())

        // 顯示或隱藏角色
        let visibility = NSMenuItem(
            title: "Hide Pet",
            action: #selector(togglePetVisibility(_:)),
            keyEquivalent: ""
        )

        visibility.target = self
        menu.addItem(visibility)
        visibilityItem = visibility

        // 分隔線
        menu.addItem(.separator())

        // 結束 App
        let quit = NSMenuItem(
            title: "Quit Desktop Pet",
            action: #selector(quitApp(_:)),
            keyEquivalent: ""
        )

        quit.target = self
        menu.addItem(quit)

        // 更新目前模式的勾選狀態
        updateMenuState()

        // 將選單指定給選單列項目
        item.menu = menu
    }


    // MARK: - Menu Actions

    // 切換為 Normal Mode
    @objc private func enableNormalMode(_ sender: NSMenuItem) {

        // 關閉 Focus Mode
        isFocusMode = false

        // 允許角色接收滑鼠事件
        window?.ignoresMouseEvents = false

        // 更新選單
        updateMenuState()
    }

    // 切換為 Focus Mode
    @objc private func enableFocusMode(_ sender: NSMenuItem) {

        // 啟用 Focus Mode
        isFocusMode = true

        // 讓滑鼠事件穿透視窗
        window?.ignoresMouseEvents = true

        // 更新選單
        updateMenuState()
    }

    // 縮小角色
    @objc private func makePetSmaller(_ sender: NSMenuItem) {

        // 縮小為目前尺寸的 85%
        resizePet(scale: 0.85)
    }

    // 放大角色
    @objc private func makePetLarger(_ sender: NSMenuItem) {

        // 放大為目前尺寸的 115%
        resizePet(scale: 1.15)
    }

    // 隱藏或重新顯示角色
    @objc private func togglePetVisibility(_ sender: NSMenuItem) {

        // 確認視窗存在
        guard let window = window else { return }

        // 依據目前狀態決定顯示或隱藏
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.orderFrontRegardless()
        }

        // 更新選單
        updateMenuState()
    }

    // 結束整個 App
    @objc private func quitApp(_ sender: NSMenuItem) {

        // 通知 macOS 正常結束程式
        NSApp.terminate(nil)
    }

    // 更新選單目前狀態
    private func updateMenuState() {

        // 將勾選記號放在目前模式
        normalItem?.state = isFocusMode ? .off : .on
        focusItem?.state = isFocusMode ? .on : .off

        // 更新顯示或隱藏的選單文字
        visibilityItem?.title =
            window?.isVisible == true ? "Hide Pet" : "Show Pet"
    }
}


// MARK: - Main

// 指定程式進入點
@main
struct DesktopPet {

    // 在 MainActor 中執行 UI 程式
    @MainActor
    static func main() {

        // 取得 macOS App 物件
        let app = NSApplication.shared

        // 建立 AppDelegate
        let delegate = AppDelegate()

        // 設定 App 代理
        app.delegate = delegate

        // 設定為選單列輔助型 App，不佔用 Dock
        app.setActivationPolicy(.accessory)

        // 執行事件循環，並保持 delegate 存活
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
