import SwiftUI

struct TodoDetailView: View {
    @Environment(TodoManager.self) private var manager
    @Environment(NavigationManager.self) private var navigationManager

    let todo: Todo

    private var projectColor: Color {
        if let color = todo.project?.color {
            return Color(hex: color)
        }
        return Color(hex: "#9CA3AF")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Todo")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                HStack(spacing: 4) {
                    Button(action: {
                        navigationManager.navigateToTodos()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)
                    .help("Back to list")

                    Button(action: {
                        navigationManager.navigateToTodoForm(todo: todo)
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)
                    .help("Edit")

                    Button(action: deleteTodo) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Button(action: {
                            manager.toggleTodoCompletion(todo)
                        }) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundStyle(todo.isCompleted ? .green : projectColor)
                        }
                        .buttonStyle(.plain)

                        Text(todo.title ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                            .strikethrough(todo.isCompleted)
                    }

                    if let description = todo.descriptionText, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Text(description)
                                .font(.system(size: 12))
                                .foregroundStyle(.primary)
                        }
                    }

                    if let project = todo.project {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Project")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(projectColor)
                                    .frame(width: 8, height: 8)

                                Text(project.name ?? "Unnamed")
                                    .font(.system(size: 12))
                            }
                        }
                    }

                    if let workOnDate = todo.workOnDate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scheduled")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)

                                Text(workOnDate, style: .date)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
        }
    }

    private func deleteTodo() {
        manager.deleteTodo(todo)
        navigationManager.navigateToTodos()
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let context = controller.container.viewContext

    let workProject = Project(context: context)
    workProject.id = UUID()
    workProject.name = "Work"
    workProject.color = "#3B82F6"
    workProject.createdAt = Date()

    let todo = Todo(context: context)
    todo.id = UUID()
    todo.title = "Review pull requests"
    todo.descriptionText = "Check the pending PRs from the team and provide feedback"
    todo.isCompleted = false
    todo.createdAt = Date()
    todo.project = workProject
    todo.workOnDate = Date()

    try? context.save()

    let manager = TodoManager(context: context)
    let navigationManager = NavigationManager()

    return TodoDetailView(todo: todo)
        .environment(manager)
        .environment(navigationManager)
        .frame(width: 300, height: 350)
}
