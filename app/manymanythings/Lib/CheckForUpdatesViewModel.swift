//
//  CheckForUpdatesViewModel.swift
//  manymanythings
//
//  Created by De-Great Yartey on 20/02/2026.
//

import Foundation
import Sparkle

@Observable
final class CheckForUpdatesViewModel: NSObject {
    var canCheckForUpdates = false

    private let updater: SPUUpdater
    private var observation: NSKeyValueObservation?

    init(updater: SPUUpdater) {
        self.updater = updater
        super.init()
        observation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            Task { @MainActor in
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
