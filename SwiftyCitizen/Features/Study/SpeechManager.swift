import Foundation
import AVFoundation
import Combine

@MainActor
final class SpeechManager: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // non-fatal; TTS is a progressive enhancement
        }
    }

    // English-canonical. languageCode defaults to en-US and every call site relies on that default.
    func speak(_ text: String, languageCode: String? = "en-US", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode ?? "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) { isSpeaking = true }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { isSpeaking = false }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { isSpeaking = false }
}
