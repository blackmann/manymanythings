//
//  MenuBarIconManager.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import AppKit
import SwiftUI

@Observable
class MenuBarIconManager {
    var iconText: String = "3" {
        didSet {
            updateIcon()
        }
    }

    var icon: NSImage?

    init() {
        updateIcon()
    }

    private func updateIcon() {
        icon = createMenuBarIcon(text: iconText)
    }

    private func createMenuBarIcon(text: String) -> NSImage {
        let size = NSSize(width: 20, height: 16)
        let image = NSImage(size: size)

        image.lockFocus()

        NSColor.white.setFill()
        NSBezierPath(
            roundedRect: NSRect(origin: .zero, size: size),
            xRadius: 4,
            yRadius: 4
        ).fill()

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.black,
        ]

        let textSize = (text as NSString).size(withAttributes: textAttributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        NSGraphicsContext.current?.compositingOperation = .destinationOut
        (text as NSString).draw(in: textRect, withAttributes: textAttributes)

        image.unlockFocus()

        image.isTemplate = true

        return image
    }
}
