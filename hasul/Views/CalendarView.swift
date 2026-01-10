import SwiftUI
import EventKit

struct CalendarView: View {
    @Environment(CalendarManager.self) private var manager
    @Environment(EventKitManager.self) private var eventManager

    var body: some View {
        VStack(spacing: 8) {
            CalendarHeaderView()

            if eventManager.authorizationStatus == .fullAccess {
                if manager.viewMode == .twoWeek {
                    CalendarWeekView()
                } else {
                    CalendarMonthView()
                }
            } else if eventManager.authorizationStatus == .denied {
                PermissionDeniedView()
            } else {
                if manager.viewMode == .twoWeek {
                    CalendarWeekView()
                } else {
                    CalendarMonthView()
                }
            }
        }
        .padding(.horizontal, 8)
        .task {
            if eventManager.authorizationStatus == .notDetermined {
                try? await eventManager.requestAccess()
            }
        }
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)

            Text("Calendar access denied")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(height: 100)
    }
}
