import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ActivityStore
    @State private var confirmClear = false

    var body: some View {
        Form {
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
