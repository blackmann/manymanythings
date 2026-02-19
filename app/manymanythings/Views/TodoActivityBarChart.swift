import Charts
import SwiftUI

struct TodoActivityBarChart: View {
  @Environment(TodoManager.self) private var manager
  @State private var chartSelection: Date?
  @State private var selectedDate: Date = Date()
  private let calendar = Calendar.current

  private var dateRange: ClosedRange<Date> {
    let end = calendar.startOfDay(for: Date())
    let start = calendar.date(byAdding: .day, value: -13, to: end) ?? end
    return start...end
  }

  private var chartData: [TodoActivitySeriesPoint] {
    _ = manager.todos

    let completedCounts = manager.completedTodosCountByDate(for: dateRange, project: manager.selectedProject)
    let addedCounts = manager.createdTodosCountByDate(for: dateRange, project: manager.selectedProject)

    return datesInRange(dateRange).flatMap { date in
      [
        TodoActivitySeriesPoint(date: date, series: "Completed", count: completedCounts[date, default: 0]),
        TodoActivitySeriesPoint(date: date, series: "Added", count: addedCounts[date, default: 0]),
      ]
    }
  }

  private var selectedDayData: (date: Date, added: Int, completed: Int) {
    let day = calendar.startOfDay(for: selectedDate)
    let added = chartData.first { $0.series == "Added" && calendar.isDate($0.date, inSameDayAs: day) }?.count ?? 0
    let completed = chartData.first { $0.series == "Completed" && calendar.isDate($0.date, inSameDayAs: day) }?.count ?? 0
    return (day, added, completed)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
    Chart(chartData) { point in
      if calendar.isDate(point.date, inSameDayAs: selectedDate), point.series == "Added" {
        RectangleMark(x: .value("Day", point.date, unit: .day))
          .foregroundStyle(Color.secondary.opacity(0.1))
      }

      if point.series == "Added" {
        BarMark(
          x: .value("Day", point.date, unit: .day),
          y: .value("Count", point.count)
        )
        .foregroundStyle(by: .value("Series", point.series))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2))
      } else {
        BarMark(
          x: .value("Day", point.date, unit: .day),
          y: .value("Count", point.count)
        )
        .foregroundStyle(by: .value("Series", point.series))
      }

    }
    .chartXSelection(value: $chartSelection)
    .onChange(of: chartSelection) { _, newValue in
      if let newValue { selectedDate = newValue }
    }
    .chartXScale(domain: .automatic(includesZero: false))
    .chartForegroundStyleScale([
      "Added": Color.secondary.opacity(0.4),
      "Completed": Color.green,
    ])
    .chartLegend(.hidden)
    .chartYAxis {
      AxisMarks(values: .automatic(desiredCount: 3)) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
          .foregroundStyle(Color.secondary.opacity(0.3))
      }
    }
    .chartXAxis(.hidden)
    .frame(height: 40)

      VStack(alignment: .leading, spacing: 1) {
        Text(selectedDayData.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
          .font(.system(size: 10, weight: .semibold))
        HStack(spacing: 8) {
          Text("added \(selectedDayData.added)")
            .foregroundStyle(.secondary)
          Text("completed \(selectedDayData.completed)")
            .foregroundStyle(.green)
        }
        .font(.system(size: 10))
      }
    }
  }

  private func datesInRange(_ range: ClosedRange<Date>) -> [Date] {
    var dates: [Date] = []
    var date = range.lowerBound

    while date <= range.upperBound {
      dates.append(date)
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
        break
      }
      date = nextDate
    }

    return dates
  }
}

private struct TodoActivitySeriesPoint: Identifiable {
  let date: Date
  let series: String
  let count: Int

  var id: String {
    "\(series)-\(date.timeIntervalSince1970)"
  }
}
