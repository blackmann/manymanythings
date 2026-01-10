import EventKit
import SwiftUI

struct HatchedPattern: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 12
            var path = Path()

            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                x += spacing
            }

            context.stroke(path, with: .color(color.opacity(0.08)), lineWidth: 4)
        }
    }
}

struct EventListView: View {
    @Environment(CalendarManager.self) private var manager
    @Environment(EventKitManager.self) private var eventManager
    @State private var events: [EKEvent] = []

    var body: some View {
        ScrollView {
            if events.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    ForEach(events, id: \.eventIdentifier) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
        .task(id: manager.selectedDate) {
            await loadEvents()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("No events")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func loadEvents() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: manager.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let eventsByDate = await eventManager.fetchEvents(
            for: startOfDay...endOfDay
        )
        events = eventsByDate[startOfDay] ?? []
    }
}

struct EventRow: View {
    let event: EKEvent
    @State private var showingDetail = false
    @State private var isHovering = false

    private var isUnacceptedInvite: Bool {
        guard event.hasAttendees,
              let attendees = event.attendees else { return false }

        guard let currentUserAttendee = attendees.first(where: { $0.isCurrentUser }) else {
            return false
        }

        let status = currentUserAttendee.participantStatus
        return status == .pending || status == .tentative
    }

    private var timeText: String {
        if event.isAllDay {
            return "All Day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)

        return "\(startTime) - \(endTime)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack {
                if event.isAllDay {
                    Rectangle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Circle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 15)
                }
            }
            .frame(width: 15)
            .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)

                if !event.isAllDay {
                    Text(timeText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(4)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear)

                if isUnacceptedInvite {
                    HatchedPattern(color: Color(cgColor: event.calendar.cgColor))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        )
        .padding(.horizontal, 4)
        
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            showingDetail = true
        }
        .popover(isPresented: $showingDetail, arrowEdge: .leading) {
            EventDetailView(event: event)
        }
    }
}
