import AVFoundation
import Combine
import MediaPlayer
import StoreKit
import SwiftUI

enum AppTab: Hashable {
    case tonight, sounds, favourites, settings
}

@MainActor
final class DriftStore: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let timerOptions = [15, 30, 45, 60, 90, 0]
    @Published var tab: AppTab = .sounds
    @Published var selectedID: String { didSet { defaults.set(selectedID, forKey: "selected") } }
    @Published private(set) var currentID: String?
    @Published private(set) var state: PlayState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var offlineIDs: Set<String> = []
    @Published private(set) var bundledIDs: Set<String> = []
    @Published private(set) var downloadingIDs: Set<String> = []
    @Published private(set) var downloadErrors: [String: String] = [:]
    @Published private(set) var remainingSeconds: TimeInterval?
    @Published private(set) var trialDaysRemaining: Int
    @Published private(set) var isPurchased = false
    @Published private(set) var plusProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published var showPaywall = false
    @Published var purchaseError: String?
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
    @Published var loops: Bool {
        didSet {
            defaults.set(loops, forKey: "loops")
            player?.numberOfLoops = loops ? -1 : 0
        }
    }
    @Published var serverAddress: String {
        didSet { defaults.set(serverAddress, forKey: "server") }
    }
    var currentSound: Soundscape? { currentID.flatMap(Soundscape.find) }
    var usualSound: Soundscape { Soundscape.find(usualID) ?? Soundscape.free[0] }
    var selectedSound: Soundscape { Soundscape.find(selectedID) ?? usualSound }
    var isBusy: Bool { state == .loading }
    var hasPremiumAccess: Bool { isPurchased || trialDaysRemaining > 0 }
    var accessSummary: String {
        if isPurchased { return "Drift Plus is unlocked." }
        if trialDaysRemaining == 1 { return "1 day left in your free preview." }
        if trialDaysRemaining > 1 { return "\(trialDaysRemaining) days left in your free preview." }
        return "Your free preview has ended."
    }
    static let plusProductID = "com.drift.sleep.plus"

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
    private let trialStart: Date
    private var didDismissPaywall = false
    private var transactionUpdates: Task<Void, Never>?
    private let narrator = GuidedNarrator()
    private var guidedElapsed: TimeInterval = 0
    private var guidedAnchor: Date?
    private var guidedSpoken: Set<Int> = []
    private var meterTimer: Timer?
    private var waveLevel: CGFloat = 0.2
    @Published private(set) var guidedPosition: TimeInterval = 0
    @Published private(set) var wave: [CGFloat] = Array(repeating: 0.2, count: 36)
    @Published private(set) var waveTime: CGFloat = 0

    override init() {
        let prefs = UserDefaults.standard
        defaults = prefs
        let usual = prefs.string(forKey: "usual") ?? "gentle-rain"
        let resolvedUsual = Soundscape.find(usual)?.isFree == true ? usual : "gentle-rain"
        usualID = resolvedUsual
        let storedSelected = prefs.string(forKey: "selected")
        selectedID = storedSelected.flatMap { Soundscape.find($0)?.id ?? GuidedSession.find($0)?.id } ?? resolvedUsual
        favourites = Set((prefs.stringArray(forKey: "favourites") ?? []).filter {
            Soundscape.find($0) != nil || GuidedSession.find($0) != nil
        })
        let storedTimer = prefs.object(forKey: "timer") as? Int ?? 30
        timerMinutes = Self.timerOptions.contains(storedTimer) ? storedTimer : 30
        volume = min(1, max(0, prefs.object(forKey: "volume") as? Double ?? 0.7))
        loops = prefs.object(forKey: "loops") as? Bool ?? true
        serverAddress = prefs.string(forKey: "server")
            ?? (Bundle.main.object(forInfoDictionaryKey: "DriftAudioServer") as? String)
            ?? ""
        let started = TrialClock.startDate()
        trialStart = started
        trialDaysRemaining = TrialPolicy.daysRemaining(start: started, now: Date())
        super.init()
        refreshDownloads()
        configureCommands()
        observeAudioSession()
        listenForTransactions()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkDeadline() }
        }
        Task { await bootstrapAccess() }
    }

    func canPlay(_: Soundscape) -> Bool {
        hasPremiumAccess
    }

    func toggle(_ sound: Soundscape) {
        if currentID == sound.id && (state == .playing || state == .loading) { pause() }
        else { play(sound) }
    }

    func selectSound(_ sound: Soundscape, autoplay: Bool = false) {
        if selectedID != sound.id { stop() }
        selectedID = sound.id
        tab = .tonight
        if autoplay { toggle(sound) }
    }

    func selectGuided(_ session: GuidedSession, autoplay: Bool = false) {
        if selectedID != session.id { stop() }
        selectedID = session.id
        tab = .tonight
        if autoplay { playGuided(session) }
    }

    func playSelected() {
        if let session = GuidedSession.find(selectedID) {
            if currentID == session.id && (state == .playing || state == .loading) { pause() }
            else { playGuided(session) }
        } else {
            toggle(selectedSound)
        }
    }

    func play(_ sound: Soundscape) {
        selectedID = sound.id
        guard canPlay(sound) else {
            showPaywall = true
            return
        }
        if currentID == sound.id, state == .paused, player != nil { resume(); return }
        invalidatePending()
        player?.stop()
        player = nil
        deletePreview()
        resetGuided()
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
                next.numberOfLoops = loops ? -1 : 0
                next.volume = Float(volume)
                next.isMeteringEnabled = true
                guard next.prepareToPlay(), next.play() else { throw LibraryError.invalidAudio }
                player = next
                previewFile = acquiredPreview
                state = .playing
                startDeadline()
                beginWave()
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
        if GuidedSession.find(currentID ?? "") != nil, player == nil {
            captureGuidedElapsed()
            narrator.pause()
            resumeAfterInterruption = false
            if state == .playing { state = .paused }
            endWave()
            updateNowPlaying()
            return
        }
        invalidatePending()
        resumeAfterInterruption = false
        player?.pause()
        endWave()
        deadline.clear()
        remainingSeconds = nil
        if state == .playing || state == .loading { state = .paused }
        updateNowPlaying()
        deactivateSession()
    }

    func resume() {
        if let session = GuidedSession.find(currentID ?? "") {
            if player != nil {
                if state == .paused { resumeRecordedGuide() }
                else if state != .playing { playGuided(session) }
            } else if state == .paused {
                resumeGuided()
            } else if state != .playing {
                playGuided(session)
            }
            return
        }
        guard let sound = currentSound else { return }
        guard canPlay(sound) else {
            showPaywall = true
            return
        }
        guard state == .paused, let player else {
            play(sound)
            return
        }
        do {
            try activateSession()
            player.volume = Float(volume)
            guard player.play() else { throw LibraryError.invalidAudio }
            state = .playing
            errorMessage = nil
            startDeadline()
            beginWave()
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
        resetGuided()
        endWave()
        currentID = nil
        deadline.clear()
        remainingSeconds = nil
        state = .idle
        errorMessage = nil
        clearNowPlaying()
        deactivateSession()
    }

    func toggleFavourite(_ sound: Soundscape) {
        toggleFavourite(sound.id)
    }

    func toggleFavourite(_ id: String) {
        guard Soundscape.find(id) != nil || GuidedSession.find(id) != nil else { return }
        if favourites.contains(id) { favourites.remove(id) }
        else { favourites.insert(id) }
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
        if let session = GuidedSession.find(currentID ?? ""), session.recording == nil, player == nil {
            advanceGuided()
            return
        }
        let left = deadline.remaining().map { ceil($0) }
        if remainingSeconds != left { remainingSeconds = left }
        guard state == .playing else { return }
        if let left = remainingSeconds, left <= 0 { stop(); return }
        player?.volume = Float(volume) * deadline.gain()
    }

    private func startDeadline() {
        deadline.start(minutes: timerMinutes)
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
            if let session = GuidedSession.find(currentID ?? "") {
            let elapsed = player?.currentTime ?? guidedPosition
            let length = player?.duration ?? session.duration
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: session.title,
                MPMediaItemPropertyArtist: "Drift",
                MPMediaItemPropertyAlbumTitle: session.practice,
                MPMediaItemPropertyPlaybackDuration: length,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
                MPNowPlayingInfoPropertyPlaybackRate: state == .playing ? 1.0 : 0.0
            ]
            return
        }
        guard let sound = currentSound, let player else { clearNowPlaying(); return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: sound.title,
            MPMediaItemPropertyArtist: "Drift",
            MPMediaItemPropertyAlbumTitle: sound.category,
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
            self.endWave()
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

    private func playGuided(_ session: GuidedSession) {
        selectedID = session.id
        guard hasPremiumAccess else {
            showPaywall = true
            return
        }
        if currentID == session.id, state == .paused {
            if player != nil { resumeRecordedGuide() } else { resumeGuided() }
            return
        }
        invalidatePending()
        player?.stop()
        player = nil
        deletePreview()
        resetGuided()
        currentID = session.id
        state = .playing
        errorMessage = nil
        deadline.clear()
        remainingSeconds = nil
        if session.practice == "NSDR" || session.recording != nil {
            guard let url = session.recordingURL else {
                state = .error
                errorMessage = "The recording is missing from the app."
                return
            }
            narrator.stop()
            playRecordedGuide(url)
            return
        }
        do {
            try activateSession()
            guidedAnchor = Date()
            advanceGuided()
            beginWave()
            updateNowPlaying()
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            deactivateSession()
        }
    }

    private func playRecordedGuide(_ url: URL) {
        narrator.stop()
        do {
            let next = try AVAudioPlayer(contentsOf: url)
            next.delegate = self
            next.numberOfLoops = loops ? -1 : 0
            next.volume = Float(volume)
            next.isMeteringEnabled = true
            player = next
            try activateSession()
            guard next.prepareToPlay(), next.play() else { throw LibraryError.invalidAudio }
            startDeadline()
            beginWave()
            updateNowPlaying()
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            deactivateSession()
        }
    }

    private func resumeRecordedGuide() {
        guard state == .paused, let player else { return }
        do {
            try activateSession()
            player.volume = Float(volume)
            guard player.play() else { throw LibraryError.invalidAudio }
            state = .playing
            errorMessage = nil
            startDeadline()
            beginWave()
            updateNowPlaying()
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            deactivateSession()
        }
    }

    private func resumeGuided() {
        guard hasPremiumAccess else {
            showPaywall = true
            return
        }
        guard state == .paused else { return }
        do {
            try activateSession()
            guidedAnchor = Date()
            narrator.resume()
            state = .playing
            errorMessage = nil
            beginWave()
            updateNowPlaying()
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            deactivateSession()
        }
    }

    private func advanceGuided() {
        guard state == .playing, let session = GuidedSession.find(currentID ?? ""), let anchor = guidedAnchor else { return }
        let position = guidedElapsed + Date().timeIntervalSince(anchor)
        guidedPosition = position
        if position >= session.duration {
            finishGuided(session)
            return
        }
        guard let index = session.segments.indices.first(where: {
            !guidedSpoken.contains($0) && position >= session.segments[$0].start
        }) else { return }
        guard !narrator.isSpeaking else { return }
        guidedSpoken.insert(index)
        narrator.speak(session.segments[index].text, volume: Float(volume))
        updateNowPlaying()
    }

    private func finishGuided(_ session: GuidedSession) {
        if loops {
            playGuided(session)
            return
        }
        narrator.stop()
        guidedAnchor = nil
        guidedElapsed = 0
        guidedSpoken = []
        guidedPosition = session.duration
        state = .ended
        endWave()
        clearNowPlaying()
        deactivateSession()
    }

    private func beginWave() {
        meterTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sampleWave() }
        }
        RunLoop.main.add(timer, forMode: .common)
        meterTimer = timer
    }

    private func endWave() {
        meterTimer?.invalidate()
        meterTimer = nil
        waveLevel = 0.2
        wave = Array(repeating: 0.2, count: 36)
    }

    private func sampleWave() {
        guard state == .playing else { return }
        let raw: CGFloat
        if let player {
            player.updateMeters()
            raw = Self.loudness(player.averagePower(forChannel: 0))
            waveTime = CGFloat(player.currentTime)
        } else {
            raw = 0.32 + 0.2 * CGFloat(sin(Date().timeIntervalSinceReferenceDate * 1.7))
            waveTime += 1.0 / 24.0
        }
        waveLevel = waveLevel * 0.62 + raw * 0.38
        var next = wave
        if next.count != 36 { next = Array(repeating: waveLevel, count: 36) }
        next.removeFirst()
        next.append(waveLevel)
        wave = next
    }

    private static func loudness(_ decibels: Float) -> CGFloat {
        let clamped = min(0, max(-48, decibels))
        return CGFloat((clamped + 48) / 48)
    }

    private func captureGuidedElapsed() {
        if let anchor = guidedAnchor {
            guidedElapsed += max(0, Date().timeIntervalSince(anchor))
            guidedAnchor = nil
            guidedPosition = guidedElapsed
        }
    }

    private func resetGuided() {
        narrator.stop()
        guidedAnchor = nil
        guidedElapsed = 0
        guidedSpoken = []
        guidedPosition = 0
    }

    func dismissPaywall() {
        showPaywall = false
        didDismissPaywall = true
    }

    func onForeground() {
        Task { await reloadAccess(presentIfLocked: !didDismissPaywall) }
    }

    func purchasePlus() async {
        purchaseError = nil
        if plusProduct == nil { await loadProducts() }
        guard let product = plusProduct else {
            purchaseError = "Drift Plus is not available from the App Store yet."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "The App Store could not verify this purchase."
                    return
                }
                await transaction.finish()
                isPurchased = true
                showPaywall = false
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if isPurchased { showPaywall = false }
            else { purchaseError = "No Drift Plus purchase was found for this Apple ID." }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func bootstrapAccess() async {
        await reloadAccess(presentIfLocked: true)
    }

    private func reloadAccess(presentIfLocked: Bool) async {
        await loadProducts()
        await refreshEntitlements()
        trialDaysRemaining = TrialPolicy.daysRemaining(start: trialStart, now: Date())
        if let sound = currentSound, !canPlay(sound),
           state == .playing || state == .paused || state == .loading {
            stop()
            showPaywall = true
            return
        }
        if presentIfLocked, !hasPremiumAccess { showPaywall = true }
    }

    private func loadProducts() async {
        plusProduct = try? await Product.products(for: [Self.plusProductID]).first
    }

    private func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.plusProductID, transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isPurchased = unlocked
    }

    private func listenForTransactions() {
        transactionUpdates = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
                if self?.isPurchased == true { self?.showPaywall = false }
            }
        }
    }
}
