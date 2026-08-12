import Charts
import SwiftUI

struct ReportView: View {
    @ObservedObject var store: ActivityStore

    private var entries: [ActivityStore.DailyReportEntry] {
        store.reportEntries()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text("最近 7 天")
                    .font(.largeTitle.bold())
                Text("每天投入工作、休息與學習的時間")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(ActivityState.allCases) { state in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(state.title, systemImage: state.symbol)
                            .foregroundStyle(state.color)
                        Text(ActivityStore.readableDuration(store.durationToday(for: state)))
                            .font(.title3.bold())
                        Text("今天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(state.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Chart(entries) { entry in
                BarMark(
                    x: .value("日期", entry.day, unit: .day),
                    y: .value("小時", entry.hours)
                )
                .foregroundStyle(by: .value("狀態", entry.state.title))
            }
            .chartForegroundStyleScale([
                ActivityState.work.title: ActivityState.work.color,
                ActivityState.rest.title: ActivityState.rest.color,
                ActivityState.study.title: ActivityState.study.color
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.narrow).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(hours, specifier: "%.0f") 小時")
                        }
                    }
                }
            }
            .frame(minHeight: 260)
        }
        .padding(24)
    }
}
