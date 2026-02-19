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
                RoundedRectangle(cornerRadius: 12)
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

    private var isNewTodoFormOpen: Bool {
        guard case .todoForm(nil) = navigationManager.stack.last else {
            return false
        }
        return true
    }

    private struct SwitchTabItem {
        let tab: AppTab
        let title: String
        let icon: String
        let action: (NavigationManager) -> Void
    }

    private let switchTabs: [SwitchTabItem] = [
        SwitchTabItem(
            tab: .calendar,
            title: "Calendar",
            icon: "calendar",
            action: { $0.navigateToCalendar() }
        ),
        SwitchTabItem(
            tab: .todos,
            title: "Todos",
            icon: "list.bullet.below.rectangle",
            action: { $0.navigateToTodos() }
        ),
    ]

    var body: some View {
        VStack {
            HStack(spacing: 2) {
                ForEach(switchTabs, id: \.title) { item in
                    switchTabButton(item)
                }

                iconButton(systemName: "plus", accessibilityLabel: "New Todo") {
                    navigationManager.navigateToTodoForm()
                }
                .disabled(isNewTodoFormOpen)

                Spacer(minLength: 4)

                iconButton(systemName: "power", accessibilityLabel: "Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func switchTabButton(_ item: SwitchTabItem) -> some View {
        let isActive = navigationManager.currentTab == item.tab
        let itemIndex = switchTabs.firstIndex(where: { $0.tab == item.tab }) ?? 0
        let previousIndex = switchTabs.firstIndex(where: { $0.tab == navigationManager.previousTab }) ?? 0
        let insertionEdge: Edge = itemIndex >= previousIndex ? .trailing : .leading

        return Button(action: {
            item.action(navigationManager)
        }) {
            HStack(spacing: 4) {
                Image(systemName: item.icon)

                if isActive {
                    Text(item.title)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: insertionEdge).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .padding(.horizontal, isActive ? 4 : 0)
            .hoverableButton(isActive: isActive)
            .animation(.easeInOut(duration: 0.18), value: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(isActive ? "Active tab" : "Inactive tab")
    }

    private func iconButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .hoverableButton()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
