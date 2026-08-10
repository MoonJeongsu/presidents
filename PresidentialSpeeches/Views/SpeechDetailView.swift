import SwiftUI

struct SpeechDetailView: View {
    let speech: SpeechDetail?
    let isLoading: Bool
    let loadError: String?
    @ObservedObject var viewModel: SpeechDetailViewModel

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let speech {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            header(for: speech)
                            FeatureHintBanner(
                                quotaUsed: viewModel.uiState.quotaUsed,
                                quotaLimit: viewModel.uiState.quotaLimit,
                                ttsQuotaUsed: viewModel.uiState.ttsQuotaUsed,
                                ttsQuotaLimit: viewModel.uiState.ttsQuotaLimit
                            )

                            ForEach(viewModel.uiState.sentences) { sentence in
                                SentenceBlock(
                                    sentence: sentence,
                                    isSelected: viewModel.uiState.selectedIndex == sentence.index,
                                    onClick: { viewModel.onSentenceClick(sentence.index) },
                                    onSpeakClick: { viewModel.onSpeakClick(sentence.index) }
                                )
                                .id(sentence.index)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.uiState.selectedIndex) { _, newValue in
                        guard let index = newValue else { return }
                        withAnimation {
                            proxy.scrollTo(index, anchor: .center)
                        }
                    }
                }
            } else {
                Text(loadError ?? "Speech text is not available.")
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationTitle("Speech")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let body = speech?.body {
                viewModel.setSpeechBody(body)
            }
        }
        .onChange(of: speech?.body) { _, newBody in
            if let newBody {
                viewModel.setSpeechBody(newBody)
            }
        }
    }

    @ViewBuilder
    private func header(for speech: SpeechDetail) -> some View {
        if let date = speech.summary.date {
            Text(formatDisplayDate(date))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        Text(speech.summary.title)
            .font(.title2.weight(.bold))
            .padding(.top, 8)
        Text(speech.summary.presidentName)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
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

private struct FeatureHintBanner: View {
    let quotaUsed: Int
    let quotaLimit: Int
    let ttsQuotaUsed: Int
    let ttsQuotaLimit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tap any sentence to see the Korean translation.", systemImage: "character.book.closed")
                .font(.subheadline)
            Text("Today: \(quotaUsed) / \(quotaLimit) new translations")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Previously translated sentences do not use your daily limit.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            Label("Tap the speaker icon to hear the sentence in English (Neural voice).", systemImage: "speaker.wave.2")
                .font(.subheadline)
            Text("Today: \(ttsQuotaUsed) / \(ttsQuotaLimit) new speech clips")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Previously heard sentences do not use your daily limit.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SentenceBlock: View {
    let sentence: SentenceUiState
    let isSelected: Bool
    let onClick: () -> Void
    let onSpeakClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(sentence.text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onClick)

                if sentence.isSynthesizing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: onSpeakClick) {
                        Image(systemName: sentence.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .foregroundStyle(sentence.isPlaying ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play sentence audio")
                }
            }

            if sentence.ttsQuotaExceeded {
                Text("Daily speech limit reached.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let message = sentence.ttsErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if isSelected {
                if sentence.isTranslating {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text("Translating…")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                } else if sentence.quotaExceeded {
                    Text("Daily translation limit reached.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                } else if let message = sentence.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                } else if let translation = sentence.translation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Korean")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(translation)
                            .font(.body)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
