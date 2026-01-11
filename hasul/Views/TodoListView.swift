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
    @State private var showingProjectFilter = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                TextField("Search todos...", text: Binding(
                    get: { manager.searchText },
                    set: { manager.setSearchText($0) }
                ))
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
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                StyledPicker(
                    label: manager.selectedProject?.name ?? "All Projects",
                    accentColor: manager.selectedProject != nil ? Color(hex: manager.selectedProject?.color ?? "#3B82F6") : .blue
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
        }
    }
}

struct TodoRow: View {
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

            Spacer()
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
            navigationManager.navigateToTodoForm(todo: todo)
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
