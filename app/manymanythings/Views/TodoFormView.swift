import SwiftUI

struct TodoFormView: View {
    @Environment(TodoManager.self) private var manager
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(TodoFormState.self) private var formState

    let todo: Todo?

    init(todo: Todo? = nil) {
        self.todo = todo
    }

    var isEditing: Bool {
        todo != nil
    }

    var canSave: Bool {
        !formState.title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        @Bindable var formState = formState

        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Todo" : "New Todo")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                HStack(spacing: 4) {
                    Button(action: {
                        formState.reset()
                        navigationManager.pop()
                    }) {
                        Image(systemName: "x.circle")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)

                    Button(action: saveTodo) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)

                    if isEditing {
                        Button(action: deleteTodo) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                        }
                        .hoverableButton()
                        .buttonStyle(.plain)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title*")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextField("Enter title...", text: $formState.title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $formState.description)
                            .font(.system(size: 12))
                            .frame(height: 80)
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Project")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button("Manage") {
                                navigationManager.navigateToProjects()
                            }
                            .font(.system(size: 10))
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                        }

                        StyledPicker(
                            label: formState.project?.name ?? "No Project",
                            accentColor: formState.project != nil ? Color(hex: formState.project?.color ?? "#3B82F6") : .gray
                        ) {
                            Button("No Project") {
                                formState.project = nil
                            }

                            if !manager.projects.isEmpty {
                                Divider()

                                ForEach(manager.projects, id: \.id) { project in
                                    Button(project.name ?? "Unnamed") {
                                        formState.project = project
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .onAppear {
            if let todo = todo {
                formState.load(from: todo)
            }
        }
    }

    private func saveTodo() {
        let trimmedTitle = formState.title.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = formState.description.trimmingCharacters(in: .whitespaces)

        if isEditing, let todo = todo {
            manager.updateTodo(
                todo,
                title: trimmedTitle,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                project: formState.project
            )
        } else {
            manager.createTodo(
                title: trimmedTitle,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                project: formState.project
            )
        }

        formState.reset()
        navigationManager.pop()
    }

    private func deleteTodo() {
        if let todo = todo {
            manager.deleteTodo(todo)
            formState.reset()
            navigationManager.pop()
        }
    }
}

#Preview("New Todo") {
    let controller = PersistenceController(inMemory: true)
    let context = controller.container.viewContext

    // Create sample projects
    let workProject = Project(context: context)
    workProject.id = UUID()
    workProject.name = "Work"
    workProject.createdAt = Date()

    let personalProject = Project(context: context)
    personalProject.id = UUID()
    personalProject.name = "Personal"
    personalProject.createdAt = Date()

    try? context.save()

    let manager = TodoManager(context: context)
    let navigationManager = NavigationManager()
    let formState = TodoFormState()

    return TodoFormView()
        .environment(manager)
        .environment(navigationManager)
        .environment(formState)
        .frame(width: 400, height: 500)
}

#Preview("Edit Todo") {
    let controller = PersistenceController(inMemory: true)
    let context = controller.container.viewContext

    // Create sample projects
    let workProject = Project(context: context)
    workProject.id = UUID()
    workProject.name = "Work"
    workProject.createdAt = Date()

    let personalProject = Project(context: context)
    personalProject.id = UUID()
    personalProject.name = "Personal"
    personalProject.createdAt = Date()

    // Create sample todo
    let todo = Todo(context: context)
    todo.id = UUID()
    todo.title = "Sample Todo"
    todo.descriptionText = "This is a test description"
    todo.isCompleted = false
    todo.createdAt = Date()
    todo.project = workProject

    try? context.save()

    let manager = TodoManager(context: context)
    let navigationManager = NavigationManager()
    let formState = TodoFormState()
    formState.load(from: todo)

    return TodoFormView(todo: todo)
        .environment(manager)
        .environment(navigationManager)
        .environment(formState)
        .frame(width: 400, height: 500)
}
