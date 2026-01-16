//
//  ContentView.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(MenuBarIconManager.self) private var iconManager
    @Environment(CalendarManager.self) private var calendarManager
    @Environment(EventKitManager.self) private var eventManager
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(TodoManager.self) private var todoManager

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch navigationManager.currentPage {
                case .calendar:
                    calendarPageContent
                case .todos:
                    todosPageContent
                case .todoDetail:
                    todoDetailPageContent
                case .todoForm:
                    todoFormPageContent
                case .projects:
                    projectsPageContent
                case .projectForm:
                    projectFormPageContent
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Hr()

            TabsBar()
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
        }
        .frame(width: 230, height: 400)
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

    private var todosPageContent: some View {
        TodoListView()
    }

    @ViewBuilder
    private var todoDetailPageContent: some View {
        if let todo = navigationManager.editingTodo {
            TodoDetailView(todo: todo)
        }
    }

    private var todoFormPageContent: some View {
        TodoFormView(todo: navigationManager.editingTodo)
    }

    private var projectsPageContent: some View {
        ProjectListView()
    }

    private var projectFormPageContent: some View {
        ProjectFormView(project: navigationManager.editingProject)
    }
}

#Preview {
    ContentView()
        .environment(MenuBarIconManager())
}
