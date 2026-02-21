import SwiftUI

enum ToastType {
  case error
  case warning
  case success
  case neutral

  var color: Color {
    switch self {
    case .error: .red
    case .warning: .orange
    case .success: .green
    case .neutral: .blue
    }
  }

  var icon: String {
    switch self {
    case .error: "xmark.circle.fill"
    case .warning: "exclamationmark.triangle.fill"
    case .success: "checkmark.circle.fill"
    case .neutral: "info.circle.fill"
    }
  }
}

struct Toast {
  let type: ToastType
  let message: String
  var duration: TimeInterval = 1.5
}

@Observable
class ToastManager {
  var currentToast: Toast?
  var isShowingToast = false

  private var dismissTask: Task<Void, Never>?

  func show(_ toast: Toast) {
    dismissTask?.cancel()

    currentToast = toast
    withAnimation(.easeInOut(duration: 0.25)) {
      isShowingToast = true
    }

    dismissTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(toast.duration))
      guard !Task.isCancelled else { return }
      dismiss()
    }
  }

  func dismiss() {
    dismissTask?.cancel()

    withAnimation(.easeInOut(duration: 0.25)) {
      isShowingToast = false
    }

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(250))
      guard !self.isShowingToast else { return }
      self.currentToast = nil
    }
  }

  func error(_ message: String) {
    show(Toast(type: .error, message: message))
  }

  func warning(_ message: String) {
    show(Toast(type: .warning, message: message))
  }

  func success(_ message: String) {
    show(Toast(type: .success, message: message))
  }

  func neutral(_ message: String) {
    show(Toast(type: .neutral, message: message))
  }
}
