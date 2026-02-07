import SwiftUI
import CoreData

enum AppTab {
    case calendar
    case todos
    case projects
}

enum AppRoute {
    case todoDetail(Todo)
    case todoForm(Todo?)
    case projectForm(Project?)
}

enum NavigationAction {
    case push
    case pop
    case reset
    case switchTab
}

@Observable
class NavigationManager {
    var currentTab: AppTab = .calendar
    var stack: [AppRoute] = []
    var lastAction: NavigationAction = .reset
    var navigationID: Int = 0

    func switchTab(_ tab: AppTab) {
        perform(.switchTab) {
            currentTab = tab
            stack.removeAll()
        }
    }

    func push(_ route: AppRoute) {
        perform(.push) {
            stack.append(route)
        }
    }

    func pop() {
        guard !stack.isEmpty else { return }
        perform(.pop) {
            stack.removeLast()
        }
    }

    func resetToRoot() {
        perform(.reset) {
            stack.removeAll()
        }
    }

    func navigateToCalendar() {
        switchTab(.calendar)
    }

    func navigateToTodos() {
        switchTab(.todos)
    }

    func navigateToProjects() {
        switchTab(.projects)
    }

    func navigateToTodoDetail(todo: Todo) {
        push(.todoDetail(todo))
    }

    func navigateToTodoForm(todo: Todo? = nil) {
        push(.todoForm(todo))
    }

    func navigateToProjectForm(project: Project? = nil) {
        push(.projectForm(project))
    }

    func goBack() {
        pop()
    }

    private func perform(_ action: NavigationAction, _ updates: () -> Void) {
        lastAction = action
        navigationID += 1

        if action == .push || action == .pop {
            withAnimation(.easeInOut(duration: 0.18)) {
                updates()
            }
        } else {
            updates()
        }
    }
}
