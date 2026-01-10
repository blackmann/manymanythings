//
//  ContentView.swift
//  hasul
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(MenuBarIconManager.self) private var iconManager

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            ScrollView {
                mainContent
            }

            Divider()

            footerView
        }
        .frame(width: 250, height: 440)
    }

    private var headerView: some View {
        HStack {
            Text("Hasul")
                .font(.headline)
            Spacer()
        }
        .padding()
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

    private var footerView: some View {
        HStack {
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(MenuBarIconManager())
}
