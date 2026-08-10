import AVFoundation
import Foundation

@MainActor
final class SentenceAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var onComplete: (() -> Void)?

    func play(fileURL: URL, onComplete: @escaping () -> Void) {
        stop()
        self.onComplete = onComplete

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            self.onComplete?()
            self.onComplete = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            self.onComplete?()
            self.onComplete = nil
        }
    }
}
