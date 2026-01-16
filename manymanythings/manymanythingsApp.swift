//
//  manymanythingsApp.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

@main
struct manymanythingsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
