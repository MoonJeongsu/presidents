import Foundation

struct SentenceUiState: Identifiable {
    let index: Int
    let text: String
    var translation: String?
    var isTranslating = false
    var errorMessage: String?
    var quotaExceeded = false
    var isSynthesizing = false
    var isPlaying = false
    var ttsErrorMessage: String?
    var ttsQuotaExceeded = false

    var id: Int { index }
}

struct SpeechDetailUiState {
    var sentences: [SentenceUiState] = []
    var selectedIndex: Int?
    var quotaUsed = 0
    var quotaLimit = AppConfig.defaultQuotaLimit
    var ttsQuotaUsed = 0
    var ttsQuotaLimit = AppConfig.defaultQuotaLimit
}

@MainActor
final class SpeechDetailViewModel: ObservableObject {
    @Published private(set) var uiState = SpeechDetailUiState()

    private let translationRepository: TranslationRepository
    private let ttsRepository: TtsRepository
    private let audioPlayer = SentenceAudioPlayer()

    init(
        translationRepository: TranslationRepository,
        ttsRepository: TtsRepository
    ) {
        self.translationRepository = translationRepository
        self.ttsRepository = ttsRepository
        uiState.quotaUsed = translationRepository.getCachedQuotaUsed()
        uiState.quotaLimit = translationRepository.getCachedQuotaLimit()
        uiState.ttsQuotaUsed = ttsRepository.getCachedQuotaUsed()
        uiState.ttsQuotaLimit = ttsRepository.getCachedQuotaLimit()
    }

    func setSpeechBody(_ body: String) {
        audioPlayer.stop()
        let sentences = SentenceSplitter.split(body).enumerated().map { index, text in
            SentenceUiState(index: index, text: text)
        }
        uiState = SpeechDetailUiState(
            sentences: sentences,
            quotaUsed: translationRepository.getCachedQuotaUsed(),
            quotaLimit: translationRepository.getCachedQuotaLimit(),
            ttsQuotaUsed: ttsRepository.getCachedQuotaUsed(),
            ttsQuotaLimit: ttsRepository.getCachedQuotaLimit()
        )
    }

    func onSentenceClick(_ index: Int) {
        guard let sentence = uiState.sentences.first(where: { $0.index == index }) else { return }

        if uiState.selectedIndex == index, sentence.translation != nil {
            uiState.selectedIndex = nil
            return
        }

        uiState.selectedIndex = index

        if sentence.translation != nil || sentence.isTranslating {
            return
        }

        updateSentence(index) {
            $0.isTranslating = true
            $0.errorMessage = nil
            $0.quotaExceeded = false
        }

        Task {
            let result = await translationRepository.translate(sentence.text)
            switch result {
            case let .success(translatedText, _, quotaUsed, quotaLimit):
                updateSentence(index) {
                    $0.translation = translatedText
                    $0.isTranslating = false
                    $0.errorMessage = nil
                    $0.quotaExceeded = false
                }
                uiState.quotaUsed = quotaUsed
                uiState.quotaLimit = quotaLimit

            case let .quotaExceeded(quotaUsed, quotaLimit):
                updateSentence(index) {
                    $0.isTranslating = false
                    $0.quotaExceeded = true
                    $0.errorMessage = nil
                }
                uiState.quotaUsed = quotaUsed
                uiState.quotaLimit = quotaLimit

            case let .error(message):
                updateSentence(index) {
                    $0.isTranslating = false
                    $0.errorMessage = message
                    $0.quotaExceeded = false
                }
            }
        }
    }

    func onSpeakClick(_ index: Int) {
        guard let sentence = uiState.sentences.first(where: { $0.index == index }) else { return }

        if sentence.isPlaying {
            stopPlayback()
            return
        }

        if sentence.isSynthesizing {
            return
        }

        stopPlayback()

        updateSentence(index) {
            $0.isSynthesizing = true
            $0.ttsErrorMessage = nil
            $0.ttsQuotaExceeded = false
            $0.isPlaying = false
        }

        Task {
            let result = await ttsRepository.synthesize(sentence.text)
            switch result {
            case let .success(audioFile, _, quotaUsed, quotaLimit):
                uiState.ttsQuotaUsed = quotaUsed
                uiState.ttsQuotaLimit = quotaLimit
                updateSentence(index) {
                    $0.isSynthesizing = false
                    $0.isPlaying = true
                }
                audioPlayer.play(fileURL: audioFile) { [weak self] in
                    self?.updateSentence(index) {
                        $0.isPlaying = false
                    }
                }

            case let .quotaExceeded(quotaUsed, quotaLimit):
                updateSentence(index) {
                    $0.isSynthesizing = false
                    $0.ttsQuotaExceeded = true
                    $0.ttsErrorMessage = nil
                }
                uiState.ttsQuotaUsed = quotaUsed
                uiState.ttsQuotaLimit = quotaLimit

            case let .error(message):
                updateSentence(index) {
                    $0.isSynthesizing = false
                    $0.ttsErrorMessage = message
                    $0.ttsQuotaExceeded = false
                }
            }
        }
    }

    private func stopPlayback() {
        audioPlayer.stop()
        uiState.sentences = uiState.sentences.map { sentence in
            guard sentence.isPlaying else { return sentence }
            var updated = sentence
            updated.isPlaying = false
            return updated
        }
    }

    private func updateSentence(_ index: Int, transform: (inout SentenceUiState) -> Void) {
        uiState.sentences = uiState.sentences.map { sentence in
            guard sentence.index == index else { return sentence }
            var updated = sentence
            transform(&updated)
            return updated
        }
    }
}
