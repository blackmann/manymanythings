import SwiftUI

@Observable
class TodoFormState {
    var title: String = ""
    var description: String = ""
    var project: Project?

    func reset() {
        title = ""
        description = ""
        project = nil
    }

    func load(from todo: Todo) {
        title = todo.title ?? ""
        description = todo.descriptionText ?? ""
        project = todo.project
    }
}
