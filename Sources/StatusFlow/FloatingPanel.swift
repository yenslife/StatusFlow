import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: ObservableObject {
    static let opacityRange = 0.35...1.0
    static let scaleRange = 0.75...1.5

    private enum DefaultsKey {
        static let opacity = "floatingPanel.opacity"
        static let scale = "floatingPanel.scale"
    }

    @Published private(set) var isVisible = false
    @Published var opacity: Double {
        didSet {
            UserDefaults.standard.set(opacity, forKey: DefaultsKey.opacity)
            updatePanelAppearance()
        }
    }
    @Published var scale: Double {
        didSet {
            UserDefaults.standard.set(scale, forKey: DefaultsKey.scale)
            updatePanelAppearance()
        }
    }

    private var panel: NSPanel?

    init() {
        let defaults = UserDefaults.standard
        opacity = Self.opacityRange.clamped(
            defaults.object(forKey: DefaultsKey.opacity) as? Double ?? 0.9
        )
        scale = Self.scaleRange.clamped(
            defaults.object(forKey: DefaultsKey.scale) as? Double ?? 1.0
        )
    }

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
            panel.contentView = NSHostingView(
                rootView: FloatingPillView(store: store, settings: self)
            )
            updatePanelAppearance(panel)
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

    private func updatePanelAppearance(_ panel: NSPanel? = nil) {
        guard let panel = panel ?? self.panel else { return }
        panel.alphaValue = opacity
        panel.setContentSize(FloatingPillView.size(scale: scale))
    }
}

struct FloatingPillView: View {
    static let baseSize = CGSize(width: 220, height: 62)

    @ObservedObject var store: ActivityStore
    @ObservedObject var settings: FloatingPanelController

    static func size(scale: Double) -> CGSize {
        CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
    }

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
        .frame(width: Self.baseSize.width, height: Self.baseSize.height)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18)))
        .scaleEffect(settings.scale)
        .frame(
            width: Self.size(scale: settings.scale).width,
            height: Self.size(scale: settings.scale).height
        )
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
