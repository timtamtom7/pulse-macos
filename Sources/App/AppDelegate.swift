import AppKit
import SwiftUI
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel = PulseViewModel()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize PulseState singleton for shortcuts
        PulseState.shared.configure(viewModel: viewModel)

        setupMenu()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()

        SystemMonitor.shared.start()

        // Load persisted samples on startup
        _ = SettingsStore.shared.getRecentSamples(hours: 24)

        // Request notification authorization
        AlertNotificationService.shared.requestAuthorization()
    }

    func applicationWillTerminate(_ notification: Notification) {
        SystemMonitor.shared.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Menu Bar Setup
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 180)

        guard let button = statusItem.button else { return }

        button.action = #selector(togglePopover)
        button.target = self

        updateStatusItemButton(button)

        // Listen for stats updates to update the button
        SystemMonitor.shared.onStatsUpdate = { [weak self] stats in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateStatusItemButton(self.statusItem.button!)
                self.viewModel.stats = stats

                // Check for CPU/RAM spikes
                AlertNotificationService.shared.checkStats(stats)
            }
        }
    }

    private func updateStatusItemButton(_ button: NSStatusBarButton) {
        let stats = viewModel.stats

        let cpuText = String(format: "CPU %.0f%%", stats.cpuTotal)
        let ramPct = stats.ramPercentage

        let combinedText = NSMutableAttributedString()

        let cpuAttr = NSAttributedString(
            string: cpuText,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
        )
        combinedText.append(cpuAttr)

        combinedText.append(NSAttributedString(string: "  ", attributes: [:]))

        let ramBarAttr = createRamBarAttr(percentage: ramPct)
        combinedText.append(ramBarAttr)

        button.attributedTitle = combinedText
        button.toolTip = "Click to open Pulse stats"
    }

    private func createRamBarAttr(percentage: Double) -> NSAttributedString {
        let barWidth: CGFloat = 30
        let barHeight: CGFloat = 10

        let size = NSSize(width: barWidth, height: barHeight)
        let renderer = NSImage(size: size, flipped: false) { rect in
            let fillWidth = rect.width * CGFloat(min(max(percentage, 0), 1))

            NSColor.quaternaryLabelColor.setFill()
            let bgPath = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            bgPath.fill()

            let fillColor: NSColor
            if percentage < 0.7 {
                fillColor = NSColor.systemGreen
            } else if percentage < 0.9 {
                fillColor = NSColor.systemOrange
            } else {
                fillColor = NSColor.systemRed
            }
            fillColor.setFill()

            let fillRect = NSRect(x: 0, y: 0, width: fillWidth, height: rect.height)
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 2, yRadius: 2)
            fillPath.fill()

            return true
        }

        renderer.isTemplate = false
        let attachment = NSTextAttachment()
        attachment.image = renderer
        return NSAttributedString(attachment: attachment)
    }

    // MARK: - Popover Setup
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: ContentView(viewModel: viewModel))
    }

    // MARK: - Event Monitor (click outside to dismiss)
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    // MARK: - App Menu
    private func setupMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Pulse", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        if #available(macOS 13.0, *) {
            let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
            launchItem.state = isLaunchAtLogin() ? .on : .off
            appMenu.addItem(launchItem)
        }

        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Pulse", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Actions
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            if let window = popover.contentViewController?.view.window {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if isLaunchAtLogin() {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Failed to toggle launch at login: \(error)")
            }
        }
        setupMenu()
    }

    private func isLaunchAtLogin() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}

// MARK: - Global State for Shortcuts

@MainActor
final class PulseState {
    static let shared = PulseState()

    var viewModel: PulseViewModel!
    var stats: SystemStats { viewModel?.stats ?? .zero }

    private init() {}

    func configure(viewModel: PulseViewModel) {
        self.viewModel = viewModel
    }
}
