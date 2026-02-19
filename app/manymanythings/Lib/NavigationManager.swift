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

    func isSameRoute(as other: AppRoute) -> Bool {
        switch (self, other) {
        case let (.todoDetail(lhs), .todoDetail(rhs)):
            return lhs.objectID == rhs.objectID
        case let (.todoForm(lhs), .todoForm(rhs)):
            switch (lhs, rhs) {
            case let (.some(lhsTodo), .some(rhsTodo)):
                return lhsTodo.objectID == rhsTodo.objectID
            case (.none, .none):
                return true
            default:
                return false
            }
        case let (.projectForm(lhs), .projectForm(rhs)):
            switch (lhs, rhs) {
            case let (.some(lhsProject), .some(rhsProject)):
                return lhsProject.objectID == rhsProject.objectID
            case (.none, .none):
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
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
    var previousTab: AppTab = .calendar
    var stack: [AppRoute] = []
    var lastAction: NavigationAction = .reset
    var navigationID: Int = 0

    func switchTab(_ tab: AppTab) {
        perform(.switchTab) {
            previousTab = currentTab
            currentTab = tab
            stack.removeAll()
        }
    }

    func push(_ route: AppRoute) {
        if let topRoute = stack.last, topRoute.isSameRoute(as: route) {
            return
        }

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

        updates()
    }
}
