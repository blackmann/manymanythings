import SwiftUI

struct StyledPicker<Content: View>: View {
    let label: String
    let accentColor: Color
    @ViewBuilder let menuContent: () -> Content
    @State private var isHovering = false

    init(
        label: String,
        accentColor: Color = .blue,
        @ViewBuilder menuContent: @escaping () -> Content
    ) {
        self.label = label
        self.accentColor = accentColor
        self.menuContent = menuContent
    }

    var body: some View {
        Menu {
            menuContent()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor)
                    .frame(width: 3, height: 14)

                Text(label)
                    .font(.system(size: 12))

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(isHovering ? 0.15 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StyledPicker(label: "All Projects", accentColor: .blue) {
            Button("All Projects") {}
            Divider()
            Button("Work") {}
            Button("Personal") {}
        }

        StyledPicker(label: "No Project", accentColor: .gray) {
            Button("No Project") {}
        }
    }
    .padding()
    .frame(width: 300)
}
