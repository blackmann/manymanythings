//
//  TabsBar.swift
//  hasul
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct HoverableButtonStyle: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .padding(2)
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

extension View {
    func hoverableButton() -> some View {
        modifier(HoverableButtonStyle())
    }
}

struct TabsBar: View {
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .hoverableButton()
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "checklist.unchecked")
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
