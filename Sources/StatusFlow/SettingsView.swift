import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ActivityStore
    @ObservedObject var floatingPanel: FloatingPanelController
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("StatusFlow 設定")
                        .font(.title2.bold())
                    Text("調整懸浮視窗，讓它融入你的工作空間。")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(spacing: 18) {
                    appearanceCard
                    dataCard
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .confirmationDialog("確定要清除所有歷史紀錄？", isPresented: $confirmClear) {
            Button("清除", role: .destructive) { store.clearHistory() }
        }
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("顯示效果", systemImage: "rectangle.inset.filled")
                    .font(.headline)
                Spacer()
                Button("恢復預設值") {
                    floatingPanel.opacity = 0.9
                    floatingPanel.scale = 1.0
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            FloatingPillView(
                store: store,
                settings: floatingPanel,
                scaleMultiplier: 0.55,
                allowsStateSelection: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: 76)

            Divider()

            settingSlider(
                title: "透明度",
                symbol: "circle.lefthalf.filled",
                value: $floatingPanel.opacity,
                range: FloatingPanelController.opacityRange,
                step: 0.01,
                lowerLabel: "淡",
                upperLabel: "清晰"
            )

            settingSlider(
                title: "大小",
                symbol: "arrow.up.left.and.arrow.down.right",
                value: $floatingPanel.scale,
                range: FloatingPanelController.scaleRange,
                step: 0.05,
                lowerLabel: "小",
                upperLabel: "大"
            )
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator.opacity(0.55))
        }
    }

    private var dataCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "externaldrive")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text("資料管理")
                    .font(.headline)
                Text("所有狀態紀錄只會儲存在這台 Mac。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("清除紀錄", role: .destructive) {
                confirmClear = true
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator.opacity(0.55))
        }
    }

    private func settingSlider(
        title: String,
        symbol: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        lowerLabel: String,
        upperLabel: String
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(title, systemImage: symbol)
                Spacer()
                Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range, step: step)
                .tint(store.currentState.color)

            HStack {
                Text(lowerLabel)
                Spacer()
                Text(upperLabel)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }
}
