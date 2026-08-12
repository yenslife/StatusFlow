import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var store: ActivityStore
    @ObservedObject var floatingPanel: FloatingPanelController

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("目前狀態")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(store.currentState.title, systemImage: store.currentState.symbol)
                        .font(.title2.bold())
                        .foregroundStyle(store.currentState.color)
                }
                Spacer()
                Text(ActivityStore.clockDuration(store.currentElapsed))
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .contentTransition(.numericText())
            }

            HStack(spacing: 8) {
                ForEach(ActivityState.allCases) { state in
                    StateButton(
                        state: state,
                        isSelected: store.currentState == state
                    ) {
                        store.switchTo(state)
                    }
                }
            }

            Divider()

            VStack(spacing: 9) {
                HStack {
                    Text("今天")
                        .font(.headline)
                    Spacer()
                }
                ForEach(ActivityState.allCases) { state in
                    HStack {
                        Label(state.title, systemImage: state.symbol)
                            .foregroundStyle(state.color)
                        Spacer()
                        Text(ActivityStore.readableDuration(store.durationToday(for: state)))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                Button(floatingPanel.isVisible ? "隱藏懸浮視窗" : "顯示懸浮視窗") {
                    floatingPanel.toggle(store: store)
                }
                Button("查看報告") {
                    openWindow(id: "report")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                Button {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("設定")
                .accessibilityLabel("設定")
                Spacer()
                Button("結束") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
    }
}

private struct StateButton: View {
    let state: ActivityState
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: state.symbol)
                Text(state.title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("切換為\(state.title)")
    }

    private var backgroundColor: Color {
        if isSelected { return state.color.opacity(0.2) }
        return isHovered ? Color.primary.opacity(0.07) : .clear
    }
}
