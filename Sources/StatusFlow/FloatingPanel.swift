import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: ObservableObject {
    @Published private(set) var isVisible = false
    private var panel: NSPanel?

    func toggle(store: ActivityStore) {
        isVisible ? hide() : show(store: store)
    }

    private func show(store: ActivityStore) {
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 220, height: 62),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.contentView = NSHostingView(rootView: FloatingPillView(store: store))
            panel.center()
            self.panel = panel
        }
        panel?.orderFrontRegardless()
        isVisible = true
    }

    private func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }
}

struct FloatingPillView: View {
    @ObservedObject var store: ActivityStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: store.currentState.symbol)
                .font(.title2)
                .foregroundStyle(store.currentState.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.currentState.title)
                    .font(.headline)
                Text(ActivityStore.clockDuration(store.currentElapsed))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(width: 220, height: 62)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18)))
    }
}
