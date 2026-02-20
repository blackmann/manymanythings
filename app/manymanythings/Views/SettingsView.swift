//
//  SettingsView.swift
//  manymanythings
//
//  Created by De-Great Yartey on 20/02/2026.
//

import AppKit
import ServiceManagement
import Sparkle
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    @State private var automaticallyCheckForUpdates: Bool
    @State private var launchAtLoginError: String?
    @State private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        _automaticallyCheckForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
        _checkForUpdatesViewModel = State(initialValue: CheckForUpdatesViewModel(updater: updater))
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "manymanythings"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "Unknown"
    }

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 300, height: 200)
        .onAppear {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Launch at login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { _, newValue in
                    setLaunchAtLogin(newValue)
                }

            Toggle("Automatically check for updates", isOn: $automaticallyCheckForUpdates)
                .onChange(of: automaticallyCheckForUpdates) { _, newValue in
                    updater.automaticallyChecksForUpdates = newValue
                }

            Button("Check for updates") {
                checkForUpdatesViewModel.checkForUpdates()
            }
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)

            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.headline)
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text("Created by De-Great Yartey")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = error.localizedDescription
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
