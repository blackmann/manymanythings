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

  @FetchRequest private var todosForSelectedDate: FetchedResults<Todo>
  @FetchRequest private var scheduledTodosForDate: FetchedResults<Todo>
  @FetchRequest private var completedTodosForDate: FetchedResults<Todo>

  init() {
    let startOfToday = Calendar.current.startOfDay(for: Date())
    let endOfToday = Calendar.current.date(
      byAdding: .day,
      value: 1,
      to: startOfToday
    )!
    let workOnDatePredicate = NSPredicate(
      format: "workOnDate >= %@ AND workOnDate < %@",
      startOfToday as NSDate,
      endOfToday as NSDate
    )
    let completedAtPredicate = NSPredicate(
      format: "completedAt >= %@ AND completedAt < %@",
      startOfToday as NSDate,
      endOfToday as NSDate
    )
    _todosForSelectedDate = FetchRequest(
      sortDescriptors: [
        NSSortDescriptor(keyPath: \Todo.createdAt, ascending: false)
      ],
      predicate: workOnDatePredicate
    )
    _scheduledTodosForDate = FetchRequest(
      sortDescriptors: [
        NSSortDescriptor(keyPath: \Todo.createdAt, ascending: false)
      ],
      predicate: workOnDatePredicate
    )
    _completedTodosForDate = FetchRequest(
      sortDescriptors: [
        NSSortDescriptor(keyPath: \Todo.createdAt, ascending: false)
      ],
      predicate: completedAtPredicate
    )
  }

  private var dateHeaderText: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: manager.selectedDate)
  }

  private var completedTodosCount: Int {
    completedTodosForDate.count
  }

  var body: some View {
    ScrollView {
      HStack {
        Text(dateHeaderText)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.secondary)

        Spacer()

        HStack(spacing: 8) {
          Text("todo \(scheduledTodosForDate.count)")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)

          Text("done \(completedTodosCount)")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, 4)

      if displayedEvents.isEmpty && todosForSelectedDate.isEmpty {
        emptyStateView
      } else {
        VStack(spacing: 0) {
          ForEach(displayedEvents, id: \.eventIdentifier) { event in
            EventRow(event: event)
          }

          if !todosForSelectedDate.isEmpty {
            if !displayedEvents.isEmpty {
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
    .task(
      id: EventListLoadID(
        selectedDate: manager.selectedDate,
        showHeatmap: manager.showHeatmap
      )
    ) {
      await loadEvents()
    }
    .onChange(of: manager.selectedDate, initial: true) { _, newDate in
      updateTodoPredicate(for: newDate)
    }
    .onChange(of: manager.showHeatmap) { _, _ in
      updateTodoPredicate(for: manager.selectedDate)
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 8) {
      Image(systemName: "calendar")
        .font(.system(size: 24))
        .foregroundStyle(.tertiary)

      Text(manager.showHeatmap ? "No completed tasks" : "No events or todos")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var displayedEvents: [EKEvent] {
    manager.showHeatmap ? [] : events
  }

  private func updateTodoPredicate(for date: Date) {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(
      byAdding: .day,
      value: 1,
      to: startOfDay
    )!

    let workOnDatePredicate = NSPredicate(
      format: "workOnDate >= %@ AND workOnDate < %@",
      startOfDay as NSDate,
      endOfDay as NSDate
    )

    scheduledTodosForDate.nsPredicate = workOnDatePredicate
    completedTodosForDate.nsPredicate = NSPredicate(
      format: "completedAt >= %@ AND completedAt < %@",
      startOfDay as NSDate,
      endOfDay as NSDate
    )

    if manager.showHeatmap {
      todosForSelectedDate.nsPredicate = NSPredicate(
        format: "completedAt >= %@ AND completedAt < %@",
        startOfDay as NSDate,
        endOfDay as NSDate
      )
    } else {
      todosForSelectedDate.nsPredicate = workOnDatePredicate
    }
  }

  private func loadEvents() async {
    if manager.showHeatmap {
      events = []
      return
    }

    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: manager.selectedDate)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

    let eventsByDate = await eventManager.fetchEvents(
      for: startOfDay...endOfDay
    )
    events = eventsByDate[startOfDay] ?? []
  }
}

private struct EventListLoadID: Equatable {
  let selectedDate: Date
  let showHeatmap: Bool
}

struct DateTodoRow: View {
  @ObservedObject var todo: Todo
  @Environment(TodoManager.self) private var manager
  @Environment(NavigationManager.self) private var navigationManager
  @Environment(ToastManager.self) private var toastManager
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
        let willComplete = !todo.isCompleted
        manager.toggleTodoCompletion(todo)
        willComplete ? toastManager.success("Todo done") : toastManager.neutral("Todo uncompleted")
      }) {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 14))
          .foregroundStyle(projectColor)
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
        toastManager.success("Scheduled for today")
      }) {
        Label("Work on Today", systemImage: "arrow.down")
      }

      Button(action: {
        manager.setWorkOnDateToTomorrow(todo)
        toastManager.neutral("Scheduled for tomorrow")
      }) {
        Label("Work on Tomorrow", systemImage: "arrow.right")
      }

      Button(action: {
        manager.clearWorkOnDate(todo)
        toastManager.success("Schedule cleared")
      }) {
        Label("Remove from Date", systemImage: "xmark.circle")
      }

      Divider()

      Button(
        role: .destructive,
        action: {
          manager.deleteTodo(todo)
          toastManager.error("Todo deleted")
        }
      ) {
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
      let attendees = event.attendees
    else { return false }

    guard let currentUserAttendee = attendees.first(where: { $0.isCurrentUser })
    else {
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
