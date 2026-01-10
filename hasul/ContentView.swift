//
//  ContentView.swift
//  hasul
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(MenuBarIconManager.self) private var iconManager
    @Environment(CalendarManager.self) private var calendarManager
    @Environment(EventKitManager.self) private var eventManager

    var body: some View {
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

            Hr()

            TabsBar()
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
        }
        .frame(width: 230, height: 400)
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            Text("MenuBar App")
                .font(.title2)

            Text("Current icon: \(iconManager.iconText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical)

            Button("Change Icon to 5") {
                iconManager.iconText = "5"
            }
            .buttonStyle(.borderedProminent)

            Button("Reset Icon to 3") {
                iconManager.iconText = "3"
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(MenuBarIconManager())
}
