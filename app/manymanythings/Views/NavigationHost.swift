import SwiftUI

struct NavigationHost: View {
    @Environment(NavigationManager.self) private var navigationManager

    var body: some View {
        ZStack {
            if let route = navigationManager.stack.last {
                routeView(for: route)
                    .id(routeID(route))
                    .transition(transition(for: navigationManager.lastAction))
            } else {
                rootView(for: navigationManager.currentTab)
                    .id(rootID(navigationManager.currentTab))
                    .transition(transition(for: navigationManager.lastAction))
            }
        }
        .animation(animation(for: navigationManager.lastAction), value: navigationManager.navigationID)
        .overlay(backShortcutOverlay)
    }

    @ViewBuilder
    private func rootView(for tab: AppTab) -> some View {
        switch tab {
        case .calendar:
            calendarPageContent
        case .todos:
            TodoListView()
        case .projects:
            ProjectListView()
        }
    }

    @ViewBuilder
    private func routeView(for route: AppRoute) -> some View {
        switch route {
        case .todoDetail(let todo):
            TodoDetailView(todo: todo)
        case .todoForm(let todo):
            TodoFormView(todo: todo)
        case .projectForm(let project):
            ProjectFormView(project: project)
        }
    }

    private var calendarPageContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                CalendarView()
                    .padding(.vertical, 8)

                Hr()
            }
            .padding(.bottom, 4)
            .background(Color.secondary.opacity(0.05))

            EventListView()
                .frame(maxHeight: .infinity)
        }
    }

    private func transition(for action: NavigationAction) -> AnyTransition {
        switch action {
        case .push:
            return .move(edge: .trailing).combined(with: .opacity)
        case .pop:
            return .move(edge: .leading).combined(with: .opacity)
        case .reset, .switchTab:
            return .opacity
        }
    }

    private func animation(for action: NavigationAction) -> Animation? {
        switch action {
        case .push, .pop:
            return .easeInOut(duration: 0.18)
        case .reset, .switchTab:
            return nil
        }
    }

    private func routeID(_ route: AppRoute) -> String {
        switch route {
        case .todoDetail(let todo):
            return "todo-detail-\(todo.objectID.uriRepresentation().absoluteString)"
        case .todoForm(let todo):
            if let todo = todo {
                return "todo-form-\(todo.objectID.uriRepresentation().absoluteString)"
            }
            return "todo-form-new"
        case .projectForm(let project):
            if let project = project {
                return "project-form-\(project.objectID.uriRepresentation().absoluteString)"
            }
            return "project-form-new"
        }
    }

    private func rootID(_ tab: AppTab) -> String {
        switch tab {
        case .calendar:
            return "root-calendar"
        case .todos:
            return "root-todos"
        case .projects:
            return "root-projects"
        }
    }

    private var backShortcutOverlay: some View {
        Button(action: {
            navigationManager.pop()
        }) {
            EmptyView()
        }
        .keyboardShortcut("[", modifiers: .command)
        .disabled(navigationManager.stack.isEmpty)
        .opacity(0)
        .frame(width: 0, height: 0)
    }
}

#Preview {
    NavigationHost()
        .environment(NavigationManager())
        .environment(CalendarManager())
        .environment(EventKitManager())
        .environment(TodoManager(context: PersistenceController.preview.container.viewContext))
        .environment(TodoFormState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 230, height: 400)
}
