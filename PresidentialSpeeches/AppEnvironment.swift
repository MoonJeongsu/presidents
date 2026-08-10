import Foundation

final class AppEnvironment {
    let speechRepository: SpeechRepository
    let translationRepository: TranslationRepository
    let ttsRepository: TtsRepository

    init() {
        speechRepository = SpeechRepository()
        translationRepository = TranslationRepository()
        ttsRepository = TtsRepository()
    }
}
