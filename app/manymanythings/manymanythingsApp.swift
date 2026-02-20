//
//  manymanythingsApp.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI
import Sparkle

@main
struct manymanythingsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        Settings {
            SettingsView(updater: updaterController.updater)
        }
    }
}
