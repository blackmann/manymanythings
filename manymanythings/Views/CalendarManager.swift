import SwiftUI
import Foundation

enum CalendarViewMode {
    case twoWeek
    case month
}

@Observable
class CalendarManager {
    var viewMode: CalendarViewMode = .twoWeek
    var currentOffset: Int = 0
    var selectedDate: Date = Date()

    private let calendar = Calendar.current

    var displayedDateRange: ClosedRange<Date> {
        switch viewMode {
        case .twoWeek:
            return calculateTwoWeekRange(offset: currentOffset)
        case .month:
            return calculateMonthRange(offset: currentOffset)
        }
    }

    var displayTitle: String {
        let formatter = DateFormatter()

        switch viewMode {
        case .twoWeek:
            let range = displayedDateRange
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: range.lowerBound)
            formatter.dateFormat = "d"
            let end = formatter.string(from: range.upperBound)
            return "\(start)-\(end)"

        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: displayedDateRange.lowerBound)
        }
    }

    var weeks: [[Date]] {
        let range = displayedDateRange
        var result: [[Date]] = []

        switch viewMode {
        case .twoWeek:
            var currentDate = range.lowerBound

            for _ in 0..<2 {
                var currentWeek: [Date] = []
                for _ in 0..<7 {
                    currentWeek.append(currentDate)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
                result.append(currentWeek)
            }

        case .month:
            let firstDayOfMonth = range.lowerBound
            let lastDayOfMonth = range.upperBound

            let startWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            let firstWeekday = calendar.firstWeekday
            let daysToSubtract = (startWeekday - firstWeekday + 7) % 7

            var currentWeek: [Date] = []
            var currentDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth)!

            while result.count < 6 && (result.isEmpty || currentDate <= lastDayOfMonth) {
                currentWeek.append(currentDate)

                if currentWeek.count == 7 {
                    result.append(currentWeek)
                    currentWeek = []
                }

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            if !currentWeek.isEmpty {
                while currentWeek.count < 7 {
                    currentWeek.append(currentDate)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
                result.append(currentWeek)
            }
        }

        return result
    }

    func isDateInDisplayedMonth(_ date: Date) -> Bool {
        guard viewMode == .month else { return true }

        let range = displayedDateRange
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        let rangeComponents = calendar.dateComponents([.year, .month], from: range.lowerBound)

        return dateComponents.year == rangeComponents.year &&
               dateComponents.month == rangeComponents.month
    }

    func isLastDayOfWeek(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let lastDayOfWeek = (calendar.firstWeekday + 5) % 7 + 1
        return weekday == lastDayOfWeek
    }

    func navigateNext() {
        currentOffset += 1
    }
    
    func navigateToCurrent() {
        currentOffset = 0
        selectedDate = Date()
    }

    func navigatePrevious() {
        currentOffset -= 1
    }

    func toggleViewMode() {
        viewMode = viewMode == .twoWeek ? .month : .twoWeek
        currentOffset = 0
    }

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    private func calculateTwoWeekRange(offset: Int) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: Date())

        let referenceDate = calendar.date(byAdding: .weekOfYear, value: offset, to: today)!

        let currentWeekSunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate))!

        let previousWeekSunday = calendar.date(byAdding: .day, value: -7, to: currentWeekSunday)!

        let currentWeekSaturday = calendar.date(byAdding: .day, value: 6, to: currentWeekSunday)!

        return previousWeekSunday...currentWeekSaturday
    }

    private func calculateMonthRange(offset: Int) -> ClosedRange<Date> {
        let today = Date()
        let targetMonth = calendar.date(byAdding: .month, value: offset, to: today)!
        let components = calendar.dateComponents([.year, .month], from: targetMonth)
        let firstDay = calendar.date(from: components)!
        let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)!
        return firstDay...lastDay
    }
}
