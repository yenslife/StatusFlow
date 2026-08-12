import AppKit
import SwiftUI

@main
struct StatusFlowApp: App {
    @StateObject private var store = ActivityStore()
    @StateObject private var floatingPanel = FloatingPanelController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store, floatingPanel: floatingPanel)
                .frame(width: 320)
        } label: {
            Label(store.menuBarTitle, systemImage: store.currentState.symbol)
        }
        .menuBarExtraStyle(.window)

        Window("StatusFlow 報告", id: "report") {
            ReportView(store: store)
                .frame(minWidth: 680, minHeight: 470)
        }
        .defaultSize(width: 760, height: 540)

        Settings {
            SettingsView(store: store, floatingPanel: floatingPanel)
                .frame(width: 420, height: 390)
        }
    }
}
