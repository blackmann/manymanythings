import Charts
import SwiftUI

struct ProjectListView: View {
    @Environment(TodoManager.self) private var manager
    @Environment(NavigationManager.self) private var navigationManager

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Text("Projects")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer()

                    HStack(spacing: 4) {
                        if navigationManager.previousPage != nil {
                            Button(action: {
                                navigationManager.goBack()
                            }) {
                                Image(systemName: "arrow.left.circle")
                                    .font(.system(size: 13))
                            }
                            .hoverableButton()
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            navigationManager.navigateToProjectForm()
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 13))
                        }
                        .hoverableButton()
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if !manager.projects.isEmpty || manager.uncategorizedTodoCount > 0 {
                    Chart {
                        BarMark(
                            x: .value("Count", manager.uncategorizedTodoCount),
                            y: .value("Category", "todos")
                        )
                        .foregroundStyle(Color.gray)

                        ForEach(manager.projects, id: \.id) { project in
                            BarMark(
                                x: .value("Count", (project.todos as? Set<Todo>)?.count ?? 0),
                                y: .value("Category", "todos")
                            )
                            .foregroundStyle(Color(hex: project.color ?? "#9CA3AF"))
                        }
                    }
                    .chartLegend(.hidden)
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color.secondary.opacity(0.05))

            if manager.projects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)

                    Text("No projects yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Button("Create Project") {
                        navigationManager.navigateToProjectForm()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        // Uncategorized row
                        UncategorizedRowView()

                        ForEach(manager.projects, id: \.id) { project in
                            ProjectListRowView(project: project)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            manager.fetchProjects()
        }
    }
}

struct UncategorizedRowView: View {
    @Environment(TodoManager.self) private var manager
    @State private var isHovering = false

    var body: some View {
        HStack {
            Image(systemName: "tray")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Text("Uncategorized")
                .font(.system(size: 12))

            Spacer()

            Text("\(manager.uncategorizedTodoCount)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct ProjectListRowView: View {
    let project: Project
    @Environment(TodoManager.self) private var manager
    @Environment(NavigationManager.self) private var navigationManager
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

            Text("\((project.todos as? Set<Todo>)?.count ?? 0)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            manager.selectProject(project)
            navigationManager.navigateToTodos()
        }
        .contextMenu {
            Button {
                navigationManager.navigateToProjectForm(project: project)
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                todoCount = (project.todos as? Set<Todo>)?.count ?? 0
                if todoCount > 0 {
                    showingDeleteAlert = true
                } else {
                    manager.deleteProject(project, deleteTodos: false)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Delete Project & Todos", role: .destructive) {
                manager.deleteProject(project, deleteTodos: true)
            }
            Button("Delete Project Only") {
                manager.deleteProject(project, deleteTodos: false)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This project has \(todoCount) todo\(todoCount == 1 ? "" : "s"). Do you want to delete them too?"
            )
        }
    }
}

#Preview {
    ProjectListView()
        .environment(
            TodoManager(
                context: PersistenceController.preview.container.viewContext
            )
        )
        .environment(NavigationManager())
        .frame(width: 300, height: 400)
}
