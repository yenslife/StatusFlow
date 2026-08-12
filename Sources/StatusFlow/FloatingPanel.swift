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
        panel.setContentSize(FloatingPillView.size(scale: scale))
    }
}

struct FloatingPillView: View {
    static let baseSize = CGSize(width: 220, height: 62)

    @ObservedObject var store: ActivityStore
    @ObservedObject var settings: FloatingPanelController
    var scaleMultiplier = 1.0
    var allowsStateSelection = true

    private var renderScale: Double {
        settings.scale * scaleMultiplier
    }

    static func size(scale: Double) -> CGSize {
        CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if allowsStateSelection {
                Menu {
                    stateMenu
                } label: {
                    pillContent
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .buttonStyle(.plain)
                .help("切換狀態")
                .accessibilityLabel("目前是\(store.currentState.title)，點擊切換狀態")

                WindowDragHandle(scale: renderScale)
                    .padding(.trailing, 10 * renderScale)
            } else {
                pillContent
            }
        }
        .background(.ultraThinMaterial.opacity(settings.opacity))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18)))
    }

    private var pillContent: some View {
        HStack(spacing: 12 * renderScale) {
            Image(systemName: store.currentState.symbol)
                .font(.system(size: 20 * renderScale, weight: .semibold))
                .foregroundStyle(store.currentState.color)
            VStack(alignment: .leading, spacing: 2 * renderScale) {
                Text(store.currentState.title)
                    .font(.system(size: 13 * renderScale, weight: .semibold))
                Text(ActivityStore.clockDuration(store.currentElapsed))
                    .font(.system(size: 11 * renderScale, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if allowsStateSelection {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9 * renderScale, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 18 * renderScale)
            }
        }
        .padding(.horizontal, 18 * renderScale)
        .frame(
            width: Self.size(scale: renderScale).width,
            height: Self.size(scale: renderScale).height
        )
        .contentShape(Capsule())
    }

    @ViewBuilder
    private var stateMenu: some View {
        ForEach(ActivityState.allCases) { state in
            Button {
                store.switchTo(state)
            } label: {
                if state == store.currentState {
                    Label(state.title, systemImage: "checkmark")
                } else {
                    Text(state.title)
                }
            }
            .disabled(state == store.currentState)
        }
    }
}

private struct WindowDragHandle: NSViewRepresentable {
    let scale: Double

    func makeNSView(context: Context) -> DragHandleView {
        DragHandleView()
    }

    func updateNSView(_ view: DragHandleView, context: Context) {
        view.toolTip = "拖移懸浮視窗"
        view.setAccessibilityLabel("拖移懸浮視窗")
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: DragHandleView,
        context: Context
    ) -> CGSize? {
        CGSize(width: 18 * scale, height: 34 * scale)
    }
}

private final class DragHandleView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.tertiaryLabelColor.setFill()
        let dotSize = max(1.5, bounds.width * 0.12)
        let x = bounds.midX - dotSize / 2
        for offset in [-0.22, 0, 0.22] {
            let y = bounds.midY + bounds.height * offset - dotSize / 2
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: dotSize, height: dotSize)).fill()
        }
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
