import CoreData
import Foundation

@Observable
class TodoManager {
    private let context: NSManagedObjectContext

    var onTodosChanged: (() -> Void)?
    var todos: [Todo] = []
    var projects: [Project] = []
    var selectedProject: Project?
    var searchText: String = ""

    var uncategorizedTodoCount: Int {
        todos.filter { $0.project == nil }.count
    }

    var todaysTodoCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return todos.filter { todo in
            guard !todo.isCompleted else { return false }
            guard let workOnDate = todo.workOnDate else { return false }
            return Calendar.current.startOfDay(for: workOnDate) == today
        }.count
    }

    var filteredTodos: [Todo] {
        var result = todos

        if let project = selectedProject {
            result = result.filter { $0.project == project }
        }

        if !searchText.isEmpty {
            result = result.filter {
                ($0.title ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.descriptionText ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func fetchTodos() {
        let request = Todo.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Todo.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \Todo.createdAt, ascending: false)
        ]

        do {
            todos = try context.fetch(request)
        } catch {
            print("Failed to fetch todos: \(error)")
        }

        onTodosChanged?()
    }

    func createTodo(title: String, description: String? = nil, project: Project? = nil) {
        let todo = Todo(context: context)
        todo.id = UUID()
        todo.title = title
        todo.descriptionText = description
        todo.isCompleted = false
        todo.createdAt = Date()
        todo.project = project

        saveContext()
        fetchTodos()
    }

    func updateTodo(_ todo: Todo, title: String, description: String?, project: Project?) {
        todo.title = title
        todo.descriptionText = description
        todo.project = project

        saveContext()
        fetchTodos()
    }

    func toggleTodoCompletion(_ todo: Todo) {
        todo.isCompleted.toggle()
        todo.completedAt = todo.isCompleted ? Date() : nil

        saveContext()
        fetchTodos()
    }

    func setWorkOnDateToToday(_ todo: Todo) {
        todo.workOnDate = Calendar.current.startOfDay(for: Date())
        saveContext()
        fetchTodos()
    }

    func setWorkOnDateToTomorrow(_ todo: Todo) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        todo.workOnDate = Calendar.current.startOfDay(for: tomorrow)
        saveContext()
        fetchTodos()
    }

    func clearWorkOnDate(_ todo: Todo) {
        todo.workOnDate = nil
        saveContext()
        fetchTodos()
    }

    func deleteTodo(_ todo: Todo) {
        context.delete(todo)
        saveContext()
        fetchTodos()
    }

    func fetchProjects() {
        let request = Project.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Project.name, ascending: true)]

        do {
            projects = try context.fetch(request)
        } catch {
            print("Failed to fetch projects: \(error)")
        }
    }

    func createProject(name: String, color: String? = nil) -> Bool {
        let nameExists = projects.contains {
            $0.name?.lowercased() == name.lowercased()
        }
        if nameExists { return false }

        let project = Project(context: context)
        project.id = UUID()
        project.name = name
        project.color = color
        project.createdAt = Date()

        saveContext()
        fetchProjects()
        return true
    }

    func updateProject(_ project: Project, name: String, color: String?) -> Bool {
        let nameExists = projects.contains {
            $0 != project && $0.name?.lowercased() == name.lowercased()
        }
        if nameExists { return false }

        project.name = name
        project.color = color

        saveContext()
        fetchProjects()
        return true
    }

    func deleteProject(_ project: Project, deleteTodos: Bool = false) {
        if deleteTodos {
            if let todos = project.todos as? Set<Todo> {
                for todo in todos {
                    context.delete(todo)
                }
            }
        } else {
            if let todos = project.todos as? Set<Todo> {
                for todo in todos {
                    todo.project = nil
                }
            }
        }

        context.delete(project)
        saveContext()
        fetchProjects()
        fetchTodos()
    }

    func setSearchText(_ text: String) {
        searchText = text
    }

    func selectProject(_ project: Project?) {
        selectedProject = project
    }

    func clearFilter() {
        selectedProject = nil
        searchText = ""
    }

    func todosForDate(_ date: Date) -> [Todo] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return todos.filter { todo in
            guard let workOnDate = todo.workOnDate else { return false }
            return calendar.startOfDay(for: workOnDate) == startOfDay
        }
    }

    func completedTodosCountByDate(for dateRange: ClosedRange<Date>, project: Project? = nil) -> [Date: Int] {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let rangeEnd = calendar.startOfDay(for: dateRange.upperBound)
        guard let nextDayAfterRange = calendar.date(byAdding: .day, value: 1, to: rangeEnd) else {
            return [:]
        }

        let request = Todo.fetchRequest()
        if let project {
            request.predicate = NSPredicate(
                format: "completedAt >= %@ AND completedAt < %@ AND project == %@",
                rangeStart as NSDate,
                nextDayAfterRange as NSDate,
                project
            )
        } else {
            request.predicate = NSPredicate(
                format: "completedAt >= %@ AND completedAt < %@",
                rangeStart as NSDate,
                nextDayAfterRange as NSDate
            )
        }

        do {
            let completedTodos = try context.fetch(request)
            var countsByDate: [Date: Int] = [:]

            for todo in completedTodos {
                guard let completedAt = todo.completedAt else { continue }
                let day = calendar.startOfDay(for: completedAt)
                countsByDate[day, default: 0] += 1
            }

            return countsByDate
        } catch {
            print("Failed to fetch completed todos by date: \(error)")
            return [:]
        }
    }

    func createdTodosCountByDate(for dateRange: ClosedRange<Date>, project: Project? = nil) -> [Date: Int] {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let rangeEnd = calendar.startOfDay(for: dateRange.upperBound)
        guard let nextDayAfterRange = calendar.date(byAdding: .day, value: 1, to: rangeEnd) else {
            return [:]
        }

        let request = Todo.fetchRequest()
        if let project {
            request.predicate = NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@ AND project == %@",
                rangeStart as NSDate,
                nextDayAfterRange as NSDate,
                project
            )
        } else {
            request.predicate = NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@",
                rangeStart as NSDate,
                nextDayAfterRange as NSDate
            )
        }

        do {
            let createdTodos = try context.fetch(request)
            var countsByDate: [Date: Int] = [:]

            for todo in createdTodos {
                guard let createdAt = todo.createdAt else { continue }
                let day = calendar.startOfDay(for: createdAt)
                countsByDate[day, default: 0] += 1
            }

            return countsByDate
        } catch {
            print("Failed to fetch created todos by date: \(error)")
            return [:]
        }
    }

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
