import AVFoundation

@MainActor
final class GuidedNarrator {
    private let speaker = AVSpeechSynthesizer()

    var isSpeaking: Bool { speaker.isSpeaking }

    func speak(_ text: String, volume: Float) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.86
        utterance.pitchMultiplier = 0.92
        utterance.volume = volume
        utterance.preUtteranceDelay = 0.2
        speaker.speak(utterance)
    }

    func pause() {
        if speaker.isSpeaking { speaker.pauseSpeaking(at: .word) }
    }

    func resume() {
        if speaker.isPaused { speaker.continueSpeaking() }
    }

    func stop() {
        if speaker.isSpeaking || speaker.isPaused { speaker.stopSpeaking(at: .immediate) }
    }

    private var voice: AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        return english.first { $0.quality == .premium }
            ?? english.first { $0.quality == .enhanced }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
