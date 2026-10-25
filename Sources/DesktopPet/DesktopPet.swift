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
                x: 0,
                y: 0,
                width: 260,
                height: 320
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

        let contentView  = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 320))

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        let imageView = NSImageView(frame: contentView.bounds)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.imageFrameStyle = .none
        imageView.autoresizingMask = [.width, .height]

        if let imageURL = Bundle.module.url(
            forResource: "pet",
            withExtension: "png"
        ),
        let image = NSImage(contentsOf: imageURL){
                imageView.image = image
        }else{
            imageView.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Desktop Pet")
            imageView.contentTintColor = .systemPink
            print("找不到 pet.png，使用備用圖示")
        }
        contentView.addSubview(imageView)
        window.contentView = contentView

        if let screen = NSScreen.main{
            let area = screen.visibleFrame
            let x = area.maxX - window.frame.width - 24
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