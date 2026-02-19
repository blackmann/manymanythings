import SwiftUI
import EventKit

struct CalendarMonthView: View {
    @Environment(CalendarManager.self) private var manager
    @Environment(EventKitManager.self) private var eventManager
    @State private var events: [Date: [EKEvent]] = [:]

    var body: some View {
        Group {
            if manager.showHeatmap {
                ActivityHeatmapView()
            } else {
                CalendarGridView(eventsByDate: events)
            }
        }
        .task(id: manager.displayedDateRange) {
            events = await eventManager.fetchEvents(for: manager.displayedDateRange)
        }
    }
}
