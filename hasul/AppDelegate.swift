//
//  AppDelegate.swift
//  hasul
//
//  Created by De-Great Yartey on 10/01/2026.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var iconManager = MenuBarIconManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusItemIcon()
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 250, height: 440)
        popover.behavior = .transient  // Auto-dismiss on outside click
        popover.animates = true
        popover.delegate = self

        let contentView = ContentView()
            .background(Color(NSColor.windowBackgroundColor))
            .environment(iconManager)
        popover.contentViewController = NSHostingController(rootView: contentView)

        setupIconObserver()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)  // Ensure focus
        }
    }

    private func updateStatusItemIcon() {
        if let button = statusItem.button {
            button.image = iconManager.icon
        }
    }

    private func setupIconObserver() {
        func observeIcon() {
            withObservationTracking {
                _ = iconManager.icon
            } onChange: {
                Task { @MainActor in
                    self.updateStatusItemIcon()
                    observeIcon()
                }
            }
        }
        observeIcon()
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }
}
