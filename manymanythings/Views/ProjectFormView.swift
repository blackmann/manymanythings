import SwiftUI

struct ProjectFormView: View {
    @Environment(TodoManager.self) private var manager
    @Environment(NavigationManager.self) private var navigationManager

    let project: Project?

    @State private var name: String = ""
    @State private var selectedColor: String = projectColors[0]
    @State private var showDuplicateError: Bool = false

    static let projectColors = ["#EF4444", "#F97316", "#EAB308", "#22C55E", "#3B82F6", "#A855F7"]

    init(project: Project? = nil) {
        self.project = project
        _name = State(initialValue: project?.name ?? "")
        _selectedColor = State(initialValue: project?.color ?? Self.projectColors[0])
    }

    var isEditing: Bool {
        project != nil
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Project" : "New Project")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                HStack(spacing: 4) {
                    Button(action: {
                        navigationManager.goBack()
                    }) {
                        Image(systemName: "x.circle")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)

                    Button(action: saveProject) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 13))
                    }
                    .hoverableButton()
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name*")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    TextField("Project name...", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .onChange(of: name) {
                            showDuplicateError = false
                        }

                    if showDuplicateError {
                        Text("A project with this name already exists")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Color")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(Self.projectColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .padding()

            Spacer()
        }
    }

    private func saveProject() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        var success: Bool
        if isEditing, let project = project {
            success = manager.updateProject(project, name: trimmedName, color: selectedColor)
        } else {
            success = manager.createProject(name: trimmedName, color: selectedColor)
        }

        if success {
            navigationManager.goBack()
        } else {
            showDuplicateError = true
        }
    }
}
