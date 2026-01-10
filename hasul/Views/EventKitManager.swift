import EventKit
import Foundation

@Observable
class EventKitManager {
    private let eventStore = EKEventStore()
    var authorizationStatus: EKAuthorizationStatus = .notDetermined

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        await MainActor.run {
            authorizationStatus = granted ? .fullAccess : .denied
        }
    }

    func fetchEvents(for dateRange: ClosedRange<Date>) async -> [Date: [EKEvent]] {
        guard authorizationStatus == .fullAccess else {
            return [:]
        }

        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.lowerBound,
            end: dateRange.upperBound,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        var grouped: [Date: [EKEvent]] = [:]
        let calendar = Calendar.current

        for event in events {
            let dateKey = calendar.startOfDay(for: event.startDate)
            grouped[dateKey, default: []].append(event)
        }

        return grouped
    }
}
