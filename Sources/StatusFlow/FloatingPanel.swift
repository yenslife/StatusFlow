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
    static let buttonSize = 30.0

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
            pillBackground

            if allowsStateSelection {
                HStack(spacing: 6 * renderScale) {
                    pauseButton
                        .frame(
                            width: max(32, Self.buttonSize * renderScale),
                            height: max(32, Self.buttonSize * renderScale)
                        )
                    stateMenu
                        .frame(
                            width: max(32, Self.buttonSize * renderScale),
                            height: max(32, Self.buttonSize * renderScale)
                        )
                }
                .padding(.trailing, 12 * renderScale)
            }
        }
        .background(.ultraThinMaterial.opacity(settings.opacity))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18)))
        .contextMenu {
            if allowsStateSelection {
                stateActions
                Divider()
                pauseAction
            }
        }
    }

    private var pillBackground: some View {
        HStack(spacing: 12 * renderScale) {
            Image(systemName: store.currentState.symbol)
                .font(.system(size: 20 * renderScale, weight: .semibold))
                .foregroundStyle(store.currentState.color)
            VStack(alignment: .leading, spacing: 2 * renderScale) {
                HStack(spacing: 4 * renderScale) {
                    Text(store.currentState.title)
                    if store.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 8 * renderScale, weight: .bold))
                    }
                }
                .font(.system(size: 13 * renderScale, weight: .semibold))
                Text(ActivityStore.clockDuration(store.currentElapsed))
                    .font(.system(size: 11 * renderScale, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.leading, 18 * renderScale)
        .padding(.trailing, (allowsStateSelection ? 90 : 18) * renderScale)
        .frame(
            width: Self.size(scale: renderScale).width,
            height: Self.size(scale: renderScale).height
        )
        .contentShape(Capsule())
    }

    private var stateMenu: some View {
        Menu {
            stateActions
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10 * renderScale, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(
                    width: Self.buttonSize * renderScale,
                    height: Self.buttonSize * renderScale
                )
                .background(store.currentState.color.opacity(0.16), in: Circle())
                .overlay(Circle().strokeBorder(store.currentState.color.opacity(0.35)))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .help("切換狀態")
        .accessibilityLabel("切換目前狀態")
    }

    private var pauseButton: some View {
        Button {
            store.togglePause()
        } label: {
            Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 10 * renderScale, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(
                    width: Self.buttonSize * renderScale,
                    height: Self.buttonSize * renderScale
                )
                .background(.primary.opacity(0.07), in: Circle())
                .overlay(Circle().strokeBorder(.primary.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .help(store.isPaused ? "繼續計時" : "暫停計時")
        .accessibilityLabel(store.isPaused ? "繼續目前時段" : "暫停目前時段")
    }

    @ViewBuilder
    private var stateActions: some View {
        ForEach(ActivityState.allCases) { state in
            Button {
                store.switchTo(state)
            } label: {
                Label(state.title, systemImage: state == store.currentState ? "checkmark" : state.symbol)
            }
            .disabled(state == store.currentState)
        }
    }

    private var pauseAction: some View {
        Button {
            store.togglePause()
        } label: {
            Label(
                store.isPaused ? "繼續計時" : "暫停計時",
                systemImage: store.isPaused ? "play.fill" : "pause.fill"
            )
        }
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
