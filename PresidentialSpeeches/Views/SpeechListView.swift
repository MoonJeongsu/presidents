import SwiftUI

struct SpeechListView: View {
    let presidentName: String
    let speeches: [SpeechSummary]
    let onSpeechClick: (SpeechSummary) -> Void

    var body: some View {
        List(speeches) { speech in
            Button {
                onSpeechClick(speech)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    if let date = speech.date {
                        Text(formatDisplayDate(date))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(speech.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle(presidentName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            Text("\(speeches.count) speeches · sorted by date")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom) {
            if AppConfig.showAds {
                Text("Ad banner placeholder")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
            }
        }
    }

    private func formatDisplayDate(_ isoDate: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: isoDate) else { return isoDate }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
