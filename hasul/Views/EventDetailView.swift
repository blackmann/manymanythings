import SwiftUI
import EventKit

struct EventDetailView: View {
    let event: EKEvent

    private var timeText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none

        if event.isAllDay {
            return "All Day • \(dateFormatter.string(from: event.startDate))"
        } else {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let start = timeFormatter.string(from: event.startDate)
            let end = timeFormatter.string(from: event.endDate)
            return "\(start) - \(end) • \(dateFormatter.string(from: event.startDate))"
        }
    }

    private var recurrenceText: String? {
        guard let rule = event.recurrenceRules?.first else { return nil }

        switch rule.frequency {
        case .daily: return "Repeats daily"
        case .weekly: return "Repeats weekly"
        case .monthly: return "Repeats monthly"
        case .yearly: return "Repeats yearly"
        @unknown default: return "Repeats"
        }
    }

    private var attendeeText: String? {
        guard let attendees = event.attendees, !attendees.isEmpty else { return nil }

        let organizerName = event.organizer?.name ?? "Unknown"
        let attendeeCount = attendees.count

        if attendeeCount == 1 {
            return organizerName
        } else {
            return "\(organizerName) + \(attendeeCount - 1) \(attendeeCount - 1 == 1 ? "other" : "others")"
        }
    }

    private var calendarColor: Color {
        Color(cgColor: event.calendar.cgColor)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(event.title ?? "Untitled Event")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Circle()
                        .fill(calendarColor)
                        .frame(width: 8, height: 8)

                    Text(event.calendar.title)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                DetailRow(icon: "clock", text: timeText)

                if let location = event.location, !location.isEmpty {
                    DetailRow(icon: "mappin.circle.fill", text: location)
                }

                if let url = event.url {
                    DetailRow(icon: "globe", text: url.absoluteString, isLink: true)
                        .onTapGesture {
                            NSWorkspace.shared.open(url)
                        }
                }

                if let attendeeText = attendeeText {
                    DetailRow(icon: "person.2.fill", text: attendeeText)
                }

                if let recurrenceText = recurrenceText {
                    DetailRow(icon: "repeat", text: recurrenceText)
                }

                if let notes = event.notes, !notes.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    NotesSection(notes: notes)
                }
            }
            .padding(16)
        }
        .frame(width: 300)
        .frame(maxHeight: 400)
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    var isLink: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(isLink ? .blue : .primary)
                .textSelection(.enabled)
        }
    }
}

struct NotesSection: View {
    let notes: String

    private var attributedNotes: AttributedString {
        let nsAttributedString = NSMutableAttributedString(string: notes)

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: notes, range: NSRange(location: 0, length: nsAttributedString.length))

            for match in matches {
                if let url = match.url {
                    nsAttributedString.addAttribute(.link, value: url, range: match.range)
                }
            }
        }

        return AttributedString(nsAttributedString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                Text(attributedNotes)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 150)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
