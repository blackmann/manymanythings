import SwiftUI

struct ActivityHeatmapView: View {
    @Environment(CalendarManager.self) private var manager
    @Environment(TodoManager.self) private var todoManager

    private var completedCountsByDate: [Date: Int] {
        _ = todoManager.todos
        return todoManager.completedTodosCountByDate(for: manager.displayedDateRange)
    }

    var body: some View {
        VStack(spacing: 4) {
            WeekdayHeaderRow()

            ForEach(manager.weeks.indices, id: \.self) { weekIndex in
                HeatmapDateRow(
                    dates: manager.weeks[weekIndex],
                    completedCountsByDate: completedCountsByDate,
                    selectedDate: manager.selectedDate
                ) { date in
                    manager.selectDate(date)
                }
            }
        }
        .background {
            GeometryReader { geometry in
                Color.secondary.opacity(0.05)
                    .frame(width: geometry.size.width / 7)
                    .offset(x: geometry.size.width / 7 * 6)
            }
        }
    }
}

private struct HeatmapDateRow: View {
    @Environment(CalendarManager.self) private var manager
    private let calendar = Calendar.current

    let dates: [Date]
    let completedCountsByDate: [Date: Int]
    let selectedDate: Date
    let onDateTap: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates.indices, id: \.self) { index in
                let date = dates[index]
                let day = calendar.startOfDay(for: date)
                let completionCount = completedCountsByDate[day, default: 0]

                HeatmapDateCell(
                    completionCount: completionCount,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isCurrentMonth: manager.isDateInDisplayedMonth(date)
                ) {
                    onDateTap(date)
                }
            }
        }
    }
}

private struct HeatmapDateCell: View {
    let completionCount: Int
    let isSelected: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void

    private var fillColor: Color {
        switch completionCount {
        case 0:
            return Color.secondary.opacity(0.1)
        case 1:
            return Color.green.opacity(0.3)
        case 2...3:
            return Color.green.opacity(0.55)
        default:
            return Color.green.opacity(0.85)
        }
    }

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(fillColor)
                .opacity(isCurrentMonth ? 1.0 : 0.45)
                .frame(width: 20, height: 20)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
