import AppKit

// AppDelegate 負責處理 macOS App 的生命週期
// @MainActor：確保這個類別的操作受到主執行環境保護
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // 儲存視窗物件
    // ? 表示 Optional，初始值為 nil
    var window: NSWindow?

    // App 啟動完成後，系統會呼叫這個方法
    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        // 建立一個 macOS 原生視窗
        let window = NSWindow(
            contentRect: NSRect(
                x: 200,
                y: 200,
                width: 500,
                height: 350
            ),

            // 設定視窗標題列與控制按鈕
            styleMask: [.borderless],

            // 使用緩衝區繪製
            backing: .buffered,

            // 不延遲建立視窗
            defer: false
        )

        window.isOpaque = false

        window.backgroundColor = .clear

        window.hasShadow = false

        window.level = .floating

        window.ignoresMouseEvents = true

        let contentView  = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 260))

        contentView.wantsLayer = true

        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        let label = NSTextField(labelWithString: "Desktop Pet")

        label.frame = NSRect(x: 40, y: 100, width: 220, height: 55)

        label.alignment = .center

        label.font = .systemFont(ofSize: 20, weight: .semibold)

        label.textColor = .white

        label.wantsLayer = true

        label.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor

        label.layer?.cornerRadius = 12

        label.layer?.masksToBounds = true

        contentView.addSubview(label)
        
        window.contentView = contentView

        if let screen = NSScreen.main{
            let area = screen.visibleFrame
            let x = area.maxX - 300 - 24
            let y = area.minY + 24

            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        window.orderFrontRegardless()

        // 保存視窗參照
        self.window = window
    }

    // 關閉最後一個視窗時，結束 App
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return true
    }
}


// @main：指定程式的進入點
@main
struct DesktopPet {

    // @MainActor：確保 main() 在 MainActor 隔離環境執行
    @MainActor
    static func main() {

        // 取得目前共用的 NSApplication
        let app = NSApplication.shared

        // 建立 AppDelegate
        let delegate = AppDelegate()

        // 設定 App 的代理物件
        app.delegate = delegate

        // 設定為一般 macOS 應用程式
        app.setActivationPolicy(.regular)

        // 啟動事件循環
        app.run()
    }
}