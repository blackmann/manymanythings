import SwiftUI
import EventKit

struct CalendarGridView: View {
    @Environment(CalendarManager.self) private var manager
    let eventsByDate: [Date: [EKEvent]]

    var body: some View {
        VStack(spacing: 4) {
            WeekdayHeaderRow()

            ForEach(manager.weeks.indices, id: \.self) { weekIndex in
                DateRow(
                    dates: manager.weeks[weekIndex],
                    eventsByDate: eventsByDate,
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

struct WeekdayHeaderRow: View {
    private let calendar = Calendar.current

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols.indices, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DateRow: View {
    @Environment(CalendarManager.self) private var manager
    let dates: [Date]
    let eventsByDate: [Date: [EKEvent]]
    let selectedDate: Date?
    let onDateTap: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates.indices, id: \.self) { index in
                let date = dates[index]
                DateCell(
                    date: date,
                    events: eventsByDate[Calendar.current.startOfDay(for: date)] ?? [],
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                    isToday: Calendar.current.isDateInToday(date),
                    isCurrentMonth: manager.isDateInDisplayedMonth(date)
                ) {
                    onDateTap(date)
                }
            }
        }
    }
}

struct DateCell: View {
    let date: Date
    let events: [EKEvent]
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isToday ? .blue : (isCurrentMonth ? .primary : .secondary))

                let visibleEvents = Array(events.prefix(3))
                HStack(spacing: 0) {
                    ForEach(Array(visibleEvents.enumerated()), id: \.element.eventIdentifier) { index, event in
                        let isFirst = index == 0
                        let isLast = index == visibleEvents.count - 1

                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: isFirst ? 1.5 : 0,
                                bottomLeading: isFirst ? 1.5 : 0,
                                bottomTrailing: isLast ? 1.5 : 0,
                                topTrailing: isLast ? 1.5 : 0
                            ),
                            style: .continuous
                        )
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .opacity(isCurrentMonth ? 1.0 : 0.3)
                        .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(isSelected ? Color.secondary.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
