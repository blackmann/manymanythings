//
//  AppDelegate.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let hasRegisteredLaunchAtLoginKey = "hasRegisteredLaunchAtLogin"
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var iconManager = MenuBarIconManager()
    private var calendarManager = CalendarManager()
    private var eventManager = EventKitManager()
    private var navigationManager = NavigationManager()
    private var todoManager = TodoManager()
    private var todoFormState = TodoFormState()
    private var toastManager = ToastManager()
    private var eventMonitor: Any?
    private var midnightTimer: Timer?
    private lazy var statusItemMenu: NSMenu = {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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
            .environment(toastManager)
        popover.contentViewController = NSHostingController(rootView: contentView)

        setupIconObserver()
        setupNavigationObserver()

        todoManager.onTodosChanged = { [weak self] in
            self?.updateTodoCount()
        }
        todoManager.fetchTodos()

        setupMidnightTimer()
        registerLaunchAtLoginOnFirstLaunch()
    }

    @objc private func handleStatusItemClick() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showStatusItemMenu()
            return
        }
        togglePopover()
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

    private func showStatusItemMenu() {
        guard let button = statusItem.button else { return }

        closePopover()
        statusItem.menu = statusItemMenu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openSettings() {
        closePopover()
        NSApp.activate(ignoringOtherApps: true)

        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
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
                _ = navigationManager.currentTab
                _ = navigationManager.stack
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

    private func setupMidnightTimer() {
        scheduleMidnightRefresh()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWake() {
        updateTodoCount()
        scheduleMidnightRefresh()
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
              let nextMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 1, of: tomorrow) else {
            return
        }

        let interval = nextMidnight.timeIntervalSinceNow
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.updateTodoCount()
            self?.scheduleMidnightRefresh()
        }
    }

    private func registerLaunchAtLoginOnFirstLaunch() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: hasRegisteredLaunchAtLoginKey) else { return }

        try? SMAppService.mainApp.register()
        defaults.set(true, forKey: hasRegisteredLaunchAtLoginKey)
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitor()
    }
}
