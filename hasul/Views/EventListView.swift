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
    @Environment(\.managedObjectContext) private var viewContext
    @State private var events: [EKEvent] = []

    @FetchRequest private var todosForSelectedDate: FetchedResults<Todo>

    init() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        _todosForSelectedDate = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Todo.createdAt, ascending: false)],
            predicate: NSPredicate(format: "workOnDate >= %@ AND workOnDate < %@", startOfToday as NSDate, endOfToday as NSDate)
        )
    }

    var body: some View {
        ScrollView {
            if events.isEmpty && todosForSelectedDate.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    ForEach(events, id: \.eventIdentifier) { event in
                        EventRow(event: event)
                    }

                    if !todosForSelectedDate.isEmpty {
                        if !events.isEmpty {
                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                        }

                        ForEach(todosForSelectedDate, id: \.id) { todo in
                            DateTodoRow(todo: todo)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .task(id: manager.selectedDate) {
            await loadEvents()
        }
        .onChange(of: manager.selectedDate, initial: true) { _, newDate in
            let startOfDay = Calendar.current.startOfDay(for: newDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            todosForSelectedDate.nsPredicate = NSPredicate(
                format: "workOnDate >= %@ AND workOnDate < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("No events or todos")
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

struct DateTodoRow: View {
    let todo: Todo
    @Environment(TodoManager.self) private var manager
    @Environment(NavigationManager.self) private var navigationManager
    @State private var isHovering = false

    private var projectColor: Color {
        if let color = todo.project?.color {
            return Color(hex: color)
        }
        return Color(hex: "#9CA3AF")
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                manager.toggleTodoCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(todo.isCompleted ? .green : projectColor)
            }
            .buttonStyle(.plain)

            Text(todo.title ?? "")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                .strikethrough(todo.isCompleted)
                .lineLimit(2)

            Spacer()
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            navigationManager.navigateToTodoDetail(todo: todo)
        }
        .contextMenu {
            Button(action: {
                navigationManager.navigateToTodoDetail(todo: todo)
            }) {
                Label("View", systemImage: "eye")
            }

            Button(action: {
                navigationManager.navigateToTodoForm(todo: todo)
            }) {
                Label("Edit", systemImage: "pencil")
            }

            Divider()

            Button(action: {
                manager.setWorkOnDateToToday(todo)
            }) {
                Label("Work on Today", systemImage: "arrow.down")
            }

            Button(action: {
                manager.setWorkOnDateToTomorrow(todo)
            }) {
                Label("Work on Tomorrow", systemImage: "arrow.right")
            }

            Button(action: {
                manager.clearWorkOnDate(todo)
            }) {
                Label("Remove from Date", systemImage: "xmark.circle")
            }

            Divider()

            Button(role: .destructive, action: {
                manager.deleteTodo(todo)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
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
                    .lineLimit(2)

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
