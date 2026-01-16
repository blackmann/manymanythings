//
//  TabsBar.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct HoverableButtonStyle: ViewModifier {
    @State private var isHovering = false
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        isActive
                            ? Color.secondary.opacity(0.15)
                            : (isHovering
                                ? Color.secondary.opacity(0.1) : Color.clear)
                    )
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

extension View {
    func hoverableButton(isActive: Bool = false) -> some View {
        modifier(HoverableButtonStyle(isActive: isActive))
    }
}

struct TabsBar: View {
    @Environment(NavigationManager.self) private var navigationManager

    var body: some View {
        VStack {
            HStack(spacing: 0) {

                Button(action: {
                    navigationManager.navigateToCalendar()
                }) {
                    Image(systemName: "calendar")
                        .hoverableButton(
                            isActive: navigationManager.currentPage == .calendar
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    navigationManager.navigateToProjects()
                }) {
                    Image(systemName: "folder")
                        .hoverableButton()
                }
                .buttonStyle(.plain)

                Button(action: {
                    navigationManager.navigateToTodos()
                }) {
                    Image(systemName: "checklist.unchecked")
                        .hoverableButton(
                            isActive: navigationManager.currentPage == .todos
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    navigationManager.navigateToTodoForm()
                }) {
                    Image(systemName: "plus")
                        .hoverableButton()
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .hoverableButton()
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 10))
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
