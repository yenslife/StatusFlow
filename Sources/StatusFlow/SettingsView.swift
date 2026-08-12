import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ActivityStore
    @ObservedObject var floatingPanel: FloatingPanelController
    @State private var confirmClear = false

    var body: some View {
        Form {
            Section("懸浮視窗") {
                LabeledContent("透明度") {
                    Text(floatingPanel.opacity, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $floatingPanel.opacity,
                    in: FloatingPanelController.opacityRange
                )

                LabeledContent("大小") {
                    Text(floatingPanel.scale, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $floatingPanel.scale,
                    in: FloatingPanelController.scaleRange,
                    step: 0.05
                )

                Button("恢復預設顯示效果") {
                    floatingPanel.opacity = 0.9
                    floatingPanel.scale = 1.0
                }
            }

            Section("資料") {
                Text("所有狀態紀錄只會儲存在這台 Mac。")
                    .foregroundStyle(.secondary)
                Button("清除所有歷史紀錄", role: .destructive) {
                    confirmClear = true
                }
            }
        }
        .padding()
        .confirmationDialog("確定要清除所有歷史紀錄？", isPresented: $confirmClear) {
            Button("清除", role: .destructive) { store.clearHistory() }
        }
    }
}
