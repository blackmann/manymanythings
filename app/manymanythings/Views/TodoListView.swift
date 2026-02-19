import SwiftUI

struct TodoListView: View {
  @Environment(TodoManager.self) private var manager
  @Environment(NavigationManager.self) private var navigationManager
  @State private var showingAddTodo = false

  var body: some View {
    VStack(spacing: 0) {
      TodoListHeader()
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))

      ScrollView {
        if manager.filteredTodos.isEmpty {
          emptyStateView
        } else {
          VStack(spacing: 0) {
            ForEach(manager.filteredTodos, id: \.id) { todo in
              TodoRow(todo: todo)
            }
          }
        }
      }
    }
    .task {
      manager.fetchTodos()
      manager.fetchProjects()
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 8) {
      Image(systemName: "checklist")
        .font(.system(size: 24))
        .foregroundStyle(.tertiary)

      Text(manager.searchText.isEmpty ? "No todos" : "No matching todos")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

struct TodoListHeader: View {
  @Environment(TodoManager.self) private var manager

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 4) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)

        TextField(
          "Search todos...",
          text: Binding(
            get: { manager.searchText },
            set: { manager.setSearchText($0) }
          )
        )
        .textFieldStyle(.plain)
        .font(.system(size: 11))

        if !manager.searchText.isEmpty {
          Button(action: { manager.setSearchText("") }) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 10))
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)

      Rectangle()
        .fill(Color.secondary.opacity(0.2))
        .frame(height: 1)
        .padding(.leading, 22)

      HStack {
        StyledPicker(
          label: manager.selectedProject?.name ?? "All Projects",
          accentColor: manager.selectedProject != nil
            ? Color(hex: manager.selectedProject?.color ?? "#3B82F6") : .gray,
          isEmbedded: true
        ) {
          Button("All Projects") {
            manager.selectProject(nil)
          }

          if !manager.projects.isEmpty {
            Divider()

            ForEach(manager.projects, id: \.id) { project in
              Button(project.name ?? "Unnamed") {
                manager.selectProject(project)
              }
            }
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
    }
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }
}

struct TodoRow: View {
  @ObservedObject var todo: Todo
  @Environment(TodoManager.self) private var manager
  @Environment(NavigationManager.self) private var navigationManager
  @State private var isHovering = false

  private var projectColor: Color {
    if let color = todo.project?.color {
      return Color(hex: color)
    }
    return Color(hex: "#9CA3AF")
  }

  private var isScheduledForToday: Bool {
    guard let workOnDate = todo.workOnDate else { return false }
    return Calendar.current.isDateInToday(workOnDate)
  }

  var body: some View {
    HStack(spacing: 8) {
      Button(action: {
        manager.toggleTodoCompletion(todo)
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

      ZStack {
        // Always present dot (visible or invisible based on state)
        Button(action: {
          if todo.workOnDate != nil {
            manager.clearWorkOnDate(todo)
          }
        }) {
          Circle()
            .fill(
              todo.workOnDate != nil
                ? (isScheduledForToday ? Color.blue : Color.secondary)
                : Color.clear
            )
            .frame(width: 6, height: 6)
        }
        .buttonStyle(.plain)
        .opacity(isHovering ? 0 : 1)
        .help(
          todo.workOnDate != nil ? "Has scheduled date. Click to remove." : ""
        )

        // Hover button (same position, shown on hover)
        Button(action: {
          manager.setWorkOnDateToToday(todo)
        }) {
          Image(systemName: "arrow.down")
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .padding(2)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .opacity(isHovering ? 1 : 0)
        .help("Work on today")
      }
      .frame(width: 20)
    }
    .padding(8)
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

      if todo.workOnDate != nil {
        Button(action: {
          manager.clearWorkOnDate(todo)
        }) {
          Label("Clear Scheduled Date", systemImage: "xmark.circle")
        }
      }

      Divider()

      Button(
        role: .destructive,
        action: {
          manager.deleteTodo(todo)
        }
      ) {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext

  let project = Project(context: context)
  project.id = UUID()
  project.name = "Work"
  project.createdAt = Date()

  let todo1 = Todo(context: context)
  todo1.id = UUID()
  todo1.title = "Review pull requests"
  todo1.descriptionText = "Check the pending PRs from the team"
  todo1.isCompleted = false
  todo1.createdAt = Date()
  todo1.project = project

  let todo2 = Todo(context: context)
  todo2.id = UUID()
  todo2.title = "Update documentation"
  todo2.isCompleted = false
  todo2.createdAt = Date().addingTimeInterval(-3600)

  let todo3 = Todo(context: context)
  todo3.id = UUID()
  todo3.title = "Fix login bug"
  todo3.isCompleted = true
  todo3.createdAt = Date().addingTimeInterval(-7200)
  todo3.completedAt = Date()

  return TodoListView()
    .environment(TodoManager(context: context))
    .environment(NavigationManager())
    .frame(width: 300, height: 350)
}
