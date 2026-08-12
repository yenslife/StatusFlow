import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
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
                    Button {
                        store.switchTo(state)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: state.symbol)
                            Text(state.title)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(store.currentState == state ? state.color.opacity(0.18) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
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
                Spacer()
                Button("結束") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
    }
}
