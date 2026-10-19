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
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable
            ],

            // 使用緩衝區繪製
            backing: .buffered,

            // 不延遲建立視窗
            defer: false
        )

        // 設定視窗標題
        window.title = "Desktop Pet"

        // 移動到螢幕中央
        window.center()

        // 顯示視窗
        window.makeKeyAndOrderFront(nil)

        // 保存視窗參照
        self.window = window

        // 啟用目前的 App
        NSApp.activate(ignoringOtherApps: true)
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