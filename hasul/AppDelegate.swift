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
    private var calendarManager = CalendarManager()
    private var eventManager = EventKitManager()
    private var navigationManager = NavigationManager()
    private var todoManager = TodoManager()
    private var todoFormState = TodoFormState()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusItemIcon()
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 230, height: 400)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        let contentView = ContentView()
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environment(iconManager)
            .environment(calendarManager)
            .environment(eventManager)
            .environment(navigationManager)
            .environment(todoManager)
            .environment(todoFormState)
        popover.contentViewController = NSHostingController(rootView: contentView)

        setupIconObserver()
        setupNavigationObserver()

        todoManager.onTodosChanged = { [weak self] in
            self?.updateTodoCount()
        }
        todoManager.fetchTodos()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            startEventMonitor()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
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

    private func setupNavigationObserver() {
        func observeNavigation() {
            withObservationTracking {
                _ = navigationManager.currentPage
            } onChange: {
                Task { @MainActor in
                    observeNavigation()
                }
            }
        }
        observeNavigation()
    }

    private func updateTodoCount() {
        let count = todoManager.todaysTodoCount
        iconManager.iconText = "\(count)"
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitor()
    }
}
