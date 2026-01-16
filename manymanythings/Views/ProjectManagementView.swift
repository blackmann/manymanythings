import SwiftUI

struct ProjectManagementView: View {
    @Environment(TodoManager.self) private var manager
    @State private var newProjectName: String = ""
    @State private var selectedColor: String = projectColors[0]
    @State private var showDuplicateError: Bool = false

    static let projectColors = ["#EF4444", "#F97316", "#EAB308", "#22C55E", "#3B82F6", "#A855F7"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manage Projects")
                .font(.system(size: 14, weight: .semibold))

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                TextField("New project name...", text: $newProjectName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onChange(of: newProjectName) {
                        showDuplicateError = false
                    }

                if showDuplicateError {
                    Text("A project with this name already exists")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }

                HStack(spacing: 6) {
                    ForEach(Self.projectColors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }

                    Spacer()

                    Button(action: addProject) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if manager.projects.isEmpty {
                Text("No projects yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(manager.projects, id: \.id) { project in
                            ProjectRowView(project: project)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func addProject() {
        let trimmedName = newProjectName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            let success = manager.createProject(name: trimmedName, color: selectedColor)
            if success {
                newProjectName = ""
                selectedColor = Self.projectColors[0]
            } else {
                showDuplicateError = true
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    @Environment(TodoManager.self) private var manager
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    @State private var todoCount: Int = 0

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: project.color ?? "#9CA3AF"))
                .frame(width: 10, height: 10)

            Text(project.name ?? "Unnamed")
                .font(.system(size: 12))

            Spacer()

            if isHovering {
                Button(action: {
                    todoCount = (project.todos as? Set<Todo>)?.count ?? 0
                    if todoCount > 0 {
                        showingDeleteAlert = true
                    } else {
                        manager.deleteProject(project, deleteTodos: false)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Delete Project & Todos", role: .destructive) {
                manager.deleteProject(project, deleteTodos: true)
            }
            Button("Delete Project Only") {
                manager.deleteProject(project, deleteTodos: false)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This project has \(todoCount) todo\(todoCount == 1 ? "" : "s"). Do you want to delete them too?")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
