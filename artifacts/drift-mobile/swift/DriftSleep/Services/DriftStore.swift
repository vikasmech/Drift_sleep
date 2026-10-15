import AVFoundation
import Combine
import MediaPlayer
import SwiftUI

@MainActor
final class DriftStore: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let timerOptions = [15, 30, 45, 60, 90, 0]
    @Published private(set) var currentID: String?
    @Published private(set) var state: PlayState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var offlineIDs: Set<String> = []
    @Published private(set) var bundledIDs: Set<String> = []
    @Published private(set) var downloadingIDs: Set<String> = []
    @Published private(set) var downloadErrors: [String: String] = [:]
    @Published private(set) var remainingSeconds: TimeInterval?
    @Published var usualID: String { didSet { defaults.set(usualID, forKey: "usual") } }
    @Published var favourites: Set<String> { didSet { defaults.set(Array(favourites), forKey: "favourites") } }
    @Published var timerMinutes: Int {
        didSet {
            defaults.set(timerMinutes, forKey: "timer")
            if state == .playing { startDeadline() }
        }
    }
    @Published var volume: Double {
        didSet {
            defaults.set(volume, forKey: "volume")
            player?.volume = Float(volume) * deadline.gain()
        }
    }
    @Published var serverAddress: String {
        didSet { defaults.set(serverAddress, forKey: "server") }
    }
    var currentSound: Soundscape? { currentID.flatMap(Soundscape.find) }
    var usualSound: Soundscape { Soundscape.find(usualID) ?? Soundscape.free[0] }
    var isBusy: Bool { state == .loading }

    private let defaults: UserDefaults
    private let library = AudioLibrary()
    private var player: AVAudioPlayer?
    private var previewFile: URL?
    private var playTask: Task<Void, Never>?
    private var playGeneration = UUID()
    private var deadline = SleepDeadline()
    private var ticker: Timer?
    private var observers: [NSObjectProtocol] = []
    private var resumeAfterInterruption = false
    private var remoteTargets: [(MPRemoteCommand, Any)] = []

    override init() {
        let prefs = UserDefaults.standard
        defaults = prefs
        let usual = prefs.string(forKey: "usual") ?? "gentle-rain"
        usualID = Soundscape.find(usual)?.isFree == true ? usual : "gentle-rain"
        favourites = Set((prefs.stringArray(forKey: "favourites") ?? []).filter { Soundscape.find($0) != nil })
        let storedTimer = prefs.object(forKey: "timer") as? Int ?? 30
        timerMinutes = Self.timerOptions.contains(storedTimer) ? storedTimer : 30
        volume = min(1, max(0, prefs.object(forKey: "volume") as? Double ?? 0.7))
        serverAddress = prefs.string(forKey: "server")
            ?? (Bundle.main.object(forInfoDictionaryKey: "DriftAudioServer") as? String)
            ?? ""
        super.init()
        refreshDownloads()
        configureCommands()
        observeAudioSession()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkDeadline() }
        }
    }

    func toggle(_ sound: Soundscape) {
        if currentID == sound.id && (state == .playing || state == .loading) { pause() }
        else { play(sound) }
    }

    func play(_ sound: Soundscape) {
        if currentID == sound.id, state == .paused, player != nil { resume(); return }
        invalidatePending()
        player?.stop()
        player = nil
        deletePreview()
        currentID = sound.id
        state = .loading
        errorMessage = nil
        deadline.clear()
        remainingSeconds = nil
        clearNowPlaying()
        let generation = playGeneration
        playTask = Task { [weak self] in
            guard let self else { return }
            var acquiredPreview: URL?
            do {
                let url: URL
                if sound.isFree {
                    downloadingIDs.insert(sound.id)
                    defer { downloadingIDs.remove(sound.id) }
                    url = try await library.ensure(sound, server: serverAddress)
                    refreshDownloads()
                } else {
                    url = try await library.preview(sound, server: serverAddress)
                    acquiredPreview = url
                }
                guard generation == playGeneration, !Task.isCancelled else {
                    if let acquiredPreview { try? FileManager.default.removeItem(at: acquiredPreview) }
                    return
                }
                try activateSession()
                let next = try AVAudioPlayer(contentsOf: url)
                next.delegate = self
                next.numberOfLoops = sound.isFree ? -1 : 0
                next.volume = Float(volume)
                guard next.prepareToPlay(), next.play() else { throw LibraryError.invalidAudio }
                player = next
                previewFile = acquiredPreview
                state = .playing
                startDeadline()
                updateNowPlaying()
            } catch {
                if let acquiredPreview { try? FileManager.default.removeItem(at: acquiredPreview) }
                guard generation == playGeneration else { return }
                state = .error
                errorMessage = error.localizedDescription
                deactivateSession()
            }
        }
    }

    func pause() {
        invalidatePending()
        resumeAfterInterruption = false
        player?.pause()
        deadline.clear()
        remainingSeconds = nil
        if state == .playing || state == .loading { state = .paused }
        updateNowPlaying()
        deactivateSession()
    }

    func resume() {
        guard state == .paused, let player else {
            if let currentSound { play(currentSound) }
            return
        }
        do {
            try activateSession()
            player.volume = Float(volume)
            guard player.play() else { throw LibraryError.invalidAudio }
            state = .playing
            errorMessage = nil
            startDeadline()
            updateNowPlaying()
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            deactivateSession()
        }
    }

    func stop() {
        invalidatePending()
        resumeAfterInterruption = false
        player?.stop()
        player = nil
        deletePreview()
        currentID = nil
        deadline.clear()
        remainingSeconds = nil
        state = .idle
        errorMessage = nil
        clearNowPlaying()
        deactivateSession()
    }

    func toggleFavourite(_ sound: Soundscape) {
        if favourites.contains(sound.id) { favourites.remove(sound.id) }
        else { favourites.insert(sound.id) }
    }

    func setUsual(_ sound: Soundscape) {
        if sound.isFree { usualID = sound.id }
    }

    func download(_ sound: Soundscape) async {
        guard sound.isFree, !downloadingIDs.contains(sound.id) else { return }
        downloadingIDs.insert(sound.id)
        downloadErrors[sound.id] = nil
        defer { downloadingIDs.remove(sound.id); refreshDownloads() }
        do { _ = try await library.ensure(sound, server: serverAddress) }
        catch { downloadErrors[sound.id] = error.localizedDescription }
    }

    func downloadAll() async {
        for sound in Soundscape.free { await download(sound) }
    }

    func removeDownload(_ sound: Soundscape) {
        guard !downloadingIDs.contains(sound.id), !bundledIDs.contains(sound.id) else { return }
        if currentID == sound.id { stop() }
        do { try library.remove(sound); downloadErrors[sound.id] = nil }
        catch { downloadErrors[sound.id] = error.localizedDescription }
        refreshDownloads()
    }

    func refreshDownloads() {
        offlineIDs = Set(Soundscape.free.filter { library.isSaved($0) }.map(\.id))
        bundledIDs = Set(Soundscape.free.filter { library.bundledURL($0) != nil }.map(\.id))
    }

    func checkDeadline() {
        let left = deadline.remaining().map { ceil($0) }
        if remainingSeconds != left { remainingSeconds = left }
        guard state == .playing else { return }
        if let left = remainingSeconds, left <= 0 { stop(); return }
        player?.volume = Float(volume) * deadline.gain()
    }

    private func startDeadline() {
        deadline.start(minutes: currentSound?.isFree == true ? timerMinutes : 0)
        checkDeadline()
    }

    private func invalidatePending() {
        playGeneration = UUID()
        playTask?.cancel()
        playTask = nil
    }

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func deletePreview() {
        if let previewFile { try? FileManager.default.removeItem(at: previewFile) }
        previewFile = nil
    }

    private func updateNowPlaying() {
        guard let sound = currentSound, let player else { clearNowPlaying(); return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: sound.title,
            MPMediaItemPropertyArtist: "Drift",
            MPMediaItemPropertyAlbumTitle: sound.isFree ? sound.category : "30-second preview",
            MPNowPlayingInfoPropertyPlaybackRate: state == .playing ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyIsLiveStream: sound.isFree
        ]
        if !sound.isFree {
            info[MPMediaItemPropertyPlaybackDuration] = player.duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil }

    private func configureCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
        remoteTargets.append((center.playCommand, center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }; return .success
        }))
        remoteTargets.append((center.pauseCommand, center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }; return .success
        }))
        remoteTargets.append((center.togglePlayPauseCommand, center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.state == .playing { self.pause() } else { self.resume() }
            }
            return .success
        }))
        remoteTargets.append((center.stopCommand, center.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.stop() }; return .success
        }))
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor in
                guard let self else { return }
                if type == AVAudioSession.InterruptionType.began.rawValue {
                    let wasPlaying = self.state == .playing
                    self.pause()
                    self.resumeAfterInterruption = wasPlaying
                } else if type == AVAudioSession.InterruptionType.ended.rawValue {
                    let shouldResume = self.resumeAfterInterruption
                        && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                    self.resumeAfterInterruption = false
                    if shouldResume { self.resume() }
                }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor in self?.pause() }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
                self?.state = .error
                self?.errorMessage = "iPhone audio was reset. Tap play to start again."
            }
        })
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self, weak player] in
            guard let self, let player, self.player === player else { return }
            self.deadline.clear()
            self.remainingSeconds = nil
            self.state = flag ? .ended : .error
            self.errorMessage = flag ? nil : "Playback stopped unexpectedly. Tap play to retry."
            self.clearNowPlaying()
            self.deactivateSession()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self, weak player] in
            guard let self, let player, self.player === player else { return }
            self.stop()
            self.state = .error
            self.errorMessage = "This audio could not be decoded. Try saving it again."
        }
    }
}
