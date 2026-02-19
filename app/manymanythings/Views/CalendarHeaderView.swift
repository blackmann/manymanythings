import SwiftUI

struct CalendarHeaderView: View {
  @Environment(CalendarManager.self) private var manager

  var body: some View {
    HStack {

      Text(manager.displayTitle)
        .font(.system(size: 12, weight: .semibold))
        .padding(.horizontal, 2)
        .background(Color.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 4))

      Spacer()

      HStack {
        Button(action: { manager.navigatePrevious() }) {
          Image(systemName: "chevron.left")
        }
        .buttonStyle(.plain)

        Button(action: { manager.navigateToCurrent() }) {
          Text("●")
            .font(.system(size: 10))
        }
        .buttonStyle(.plain)

        Button(action: { manager.navigateNext() }) {
          Image(systemName: "chevron.right")
        }
        .buttonStyle(.plain)
      }
      .foregroundStyle(.secondary)
      .font(.system(size: 12, weight: .semibold))

      Divider()
        .frame(height: 12)

      HStack {
        Button(action: { manager.toggleViewMode() }) {
          Image(
            systemName: manager.viewMode == .twoWeek
              ? "calendar" : "ellipsis.calendar"
          )
          .font(.system(size: 12))
          .foregroundStyle(manager.viewMode != .twoWeek ? .blue : .secondary)
        }
        .buttonStyle(.plain)

        Button(action: { manager.toggleHeatmap() }) {
          Image(systemName: "flag.pattern.checkered")
            .font(.system(size: 12))
            .foregroundStyle(manager.showHeatmap ? .green : .secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 8)
  }
}
