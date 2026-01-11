import SwiftUI
import CoreData

enum AppPage {
    case calendar
    case todos
    case todoDetail
    case todoForm
    case projects
    case projectForm
}

@Observable
class NavigationManager {
    var currentPage: AppPage = .calendar
    var previousPage: AppPage?
    var editingTodo: Todo?
    var editingProject: Project?

    func navigateToCalendar() {
        currentPage = .calendar
        editingTodo = nil
    }

    func navigateToTodos() {
        currentPage = .todos
        editingTodo = nil
    }

    func navigateToTodoDetail(todo: Todo) {
        editingTodo = todo
        currentPage = .todoDetail
    }

    func navigateToTodoForm(todo: Todo? = nil) {
        editingTodo = todo
        currentPage = .todoForm
    }

    func navigateToProjects() {
        previousPage = currentPage
        currentPage = .projects
    }

    func navigateToProjectForm(project: Project? = nil) {
        previousPage = currentPage
        editingProject = project
        currentPage = .projectForm
    }

    func goBack() {
        editingProject = nil
        currentPage = previousPage ?? .projects
        previousPage = nil
    }

    func togglePage() {
        currentPage = currentPage == .calendar ? .todos : .calendar
        editingTodo = nil
    }
}
