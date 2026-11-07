import XCTest
@testable import DriftSleep

final class DriftSleepTests: XCTestCase {
    func testSevenDayPreviewExpiresOnTheFollowingWeek() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(TrialPolicy.daysRemaining(start: start, now: start), 7)
        XCTAssertTrue(TrialPolicy.isActive(start: start, now: start.addingTimeInterval(7 * 86_400 - 1)))
        XCTAssertEqual(TrialPolicy.daysRemaining(start: start, now: start.addingTimeInterval(6 * 86_400 + 3_600)), 1)
        XCTAssertFalse(TrialPolicy.isActive(start: start, now: start.addingTimeInterval(7 * 86_400)))
        XCTAssertEqual(TrialPolicy.daysRemaining(start: start, now: start.addingTimeInterval(7 * 86_400)), 0)
    }

    func testGuidedRestSessionsPlayOnceToTheirOwnEnding() {
        XCTAssertEqual(GuidedSession.all.map(\.id), ["little-space", "nothing-more-tonight"])
        XCTAssertEqual(GuidedSession.all.map(\.practice), ["NSDR", "Yoga Nidra"])
        XCTAssertEqual(GuidedSession.all.map(\.duration), [600, 1200])
        XCTAssertEqual(GuidedSession.all.map(\.recording), ["nsdr", "yoga-nidra"])
        for session in GuidedSession.all {
            XCTAssertEqual(session.segments.first?.start, 0)
            XCTAssertLessThan(session.segments.last?.start ?? 0, session.duration)
            XCTAssertFalse(session.segments.contains { $0.text.contains("00:") || $0.text.contains("Production") })
        }
    }

    func testCataloguePreservesFiveFreeSounds() {
        XCTAssertEqual(Soundscape.all.count, 30)
        XCTAssertEqual(Set(Soundscape.all.map(\.id)).count, 30)
        XCTAssertEqual(Soundscape.free.map(\.id), [
            "gentle-rain", "ocean-waves", "brown-noise", "pink-noise", "soft-fan"
        ])
        XCTAssertEqual(Soundscape.plus.count, 25)
        XCTAssertTrue(Soundscape.plus.allSatisfy { !$0.isFree && $0.delivery == .plusStream })
        XCTAssertTrue(Soundscape.free.allSatisfy { $0.delivery == .unlimitedLoop })
        XCTAssertEqual(Soundscape.find("gentle-rain")?.filename, "loop-v2-gentle-rain.wav")
        XCTAssertEqual(Soundscape.find("rain-on-glass")?.filename, "native-rain-on-glass.mp3")
    }

    func testDeadlineAndNativeFadeAreBasedOnAbsoluteTime() {
        let now = Date(timeIntervalSince1970: 1_000)
        var deadline = SleepDeadline()
        deadline.start(minutes: 15, now: now)
        XCTAssertEqual(deadline.remaining(now: now), 900)
        XCTAssertEqual(deadline.gain(now: now.addingTimeInterval(896)), 0.5, accuracy: 0.001)
        XCTAssertEqual(deadline.remaining(now: now.addingTimeInterval(910)), 0)
        XCTAssertEqual(deadline.gain(now: now.addingTimeInterval(910)), 0)
        deadline.clear()
        XCTAssertNil(deadline.remaining())
        XCTAssertEqual(deadline.gain(), 1)
        deadline.start(minutes: 0)
        XCTAssertNil(deadline.end)
    }

    @MainActor
    func testServerRequiresHTTPSAndNoEmbeddedCredentials() {
        XCTAssertNotNil(AudioLibrary.serverURL("https://example.com"))
        XCTAssertNotNil(AudioLibrary.serverURL("https://example.com/audio-service/"))
        XCTAssertNil(AudioLibrary.serverURL("http://example.com"))
        XCTAssertNil(AudioLibrary.serverURL("https://user:password@example.com"))
        XCTAssertNil(AudioLibrary.serverURL("https://example.com?token=value"))
        XCTAssertNil(AudioLibrary.serverURL("not a URL"))
    }

    @MainActor
    func testPackagedLoopsAreValidPCMAndOfflineReady() throws {
        let library = AudioLibrary()
        for sound in Soundscape.free {
            let url = try XCTUnwrap(library.bundledURL(sound), "Run prepare-audio.sh before testing.")
            XCTAssertNoThrow(try library.validate(url, freeLoop: true))
            XCTAssertTrue(library.isSaved(sound))
        }
    }

    @MainActor
    func testHTMLCannotBecomeAPlayableDownload() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("<html>Sign in required</html>".utf8).write(to: url)
        XCTAssertThrowsError(try AudioLibrary().validate(url, freeLoop: true))
        XCTAssertThrowsError(try AudioLibrary().validate(url, freeLoop: false))
    }

    @MainActor
    func testFreeLoopValidationAllowsAudioLongerThanThePreviewCap() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }
        try writeSilentWav(to: url, seconds: 40)
        let library = AudioLibrary()
        XCTAssertNoThrow(try library.validate(url, freeLoop: true))
        XCTAssertThrowsError(try library.validate(url, freeLoop: false))
    }

    @MainActor
    func testFreeSoundPlaysAfterTrialExpiresWithoutPurchase() throws {
        let store = makeAccessStore(trialStart: expiredTrialStart(), purchased: false)
        XCTAssertEqual(store.trialDaysRemaining, 0)
        XCTAssertFalse(store.isPurchased)
        XCTAssertFalse(store.hasPremiumAccess)
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(DriftStore.plusProductID, "com.drift.sleep.plus")
        XCTAssertEqual(store.plusPriceText, "$9.99")
        XCTAssertTrue(store.accessSummary.contains("stay free"))
        XCTAssertTrue(store.accessSummary.contains("$9.99"))
        XCTAssertTrue(store.accessSummary.contains("not a subscription"))
        XCTAssertTrue(store.paywallLead.contains("stay free"))
        XCTAssertTrue(store.paywallOffer.contains("No subscription"))
        XCTAssertTrue(store.paywallOffer.contains("25"))
        for sound in Soundscape.free {
            XCTAssertTrue(store.canPlay(sound))
            XCTAssertEqual(sound.delivery, .unlimitedLoop)
        }
        let rain = try XCTUnwrap(Soundscape.find("gentle-rain"))
        store.play(rain)
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.currentID, rain.id)
        XCTAssertEqual(store.state, .loading)
        store.stop()
    }

    @MainActor
    func testPremiumSoundIsBlockedAndShowsPaywallWhenTrialExpiredAndUnpurchased() throws {
        let store = makeAccessStore(trialStart: expiredTrialStart(), purchased: false)
        XCTAssertFalse(store.showPaywall)
        let plus = try XCTUnwrap(Soundscape.find("rain-on-glass"))
        XCTAssertEqual(Soundscape.plus.count, 25)
        for sound in Soundscape.plus {
            XCTAssertFalse(store.canPlay(sound))
            XCTAssertEqual(sound.delivery, .plusStream)
        }
        store.play(plus)
        XCTAssertTrue(store.showPaywall)
        XCTAssertNil(store.currentID)
        XCTAssertEqual(store.state, .idle)
        XCTAssertFalse(store.paywallOffer.localizedCaseInsensitiveContains("per month"))
    }

    @MainActor
    func testPremiumSoundPlaysDuringTrial() throws {
        let store = makeAccessStore(trialStart: freemiumNow, purchased: false)
        XCTAssertEqual(store.trialDaysRemaining, 7)
        XCTAssertTrue(store.hasPremiumAccess)
        XCTAssertFalse(store.showPaywall)
        for sound in Soundscape.plus {
            XCTAssertTrue(store.canPlay(sound))
        }
        let plus = try XCTUnwrap(Soundscape.find("rain-on-glass"))
        store.play(plus)
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.currentID, plus.id)
        XCTAssertEqual(store.state, .loading)
        store.stop()
    }

    @MainActor
    func testPremiumSoundPlaysAfterPurchase() throws {
        let store = makeAccessStore(trialStart: expiredTrialStart(), purchased: false)
        let plus = try XCTUnwrap(Soundscape.find("rain-on-glass"))
        XCTAssertFalse(store.canPlay(plus))
        store.play(plus)
        XCTAssertTrue(store.showPaywall)
        store.applyVerifiedPurchase()
        XCTAssertTrue(store.isPurchased)
        XCTAssertTrue(store.hasPremiumAccess)
        XCTAssertFalse(store.showPaywall)
        XCTAssertTrue(store.accessSummary.contains("unlocked"))
        for sound in Soundscape.plus {
            XCTAssertTrue(store.canPlay(sound))
        }
        store.play(plus)
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.state, .loading)
        store.stop()
    }

    @MainActor
    func testRestoreUnlocksPremiumSounds() async throws {
        let store = makeAccessStore(trialStart: expiredTrialStart(), restore: { true })
        let plus = try XCTUnwrap(Soundscape.find("rain-on-glass"))
        store.play(plus)
        XCTAssertTrue(store.showPaywall)
        XCTAssertFalse(store.isPurchased)
        await store.restorePurchases()
        XCTAssertTrue(store.isPurchased)
        XCTAssertNil(store.purchaseError)
        XCTAssertFalse(store.showPaywall)
        XCTAssertTrue(store.canPlay(plus))
        store.play(plus)
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.state, .loading)
        store.stop()
    }

    @MainActor
    func testRestoreWithoutPurchaseStaysLocked() async throws {
        let store = makeAccessStore(trialStart: expiredTrialStart(), restore: { false })
        await store.restorePurchases()
        XCTAssertFalse(store.isPurchased)
        XCTAssertFalse(store.hasPremiumAccess)
        XCTAssertEqual(store.purchaseError, "No Drift Plus purchase was found for this Apple ID.")
        XCTAssertFalse(store.canPlay(try XCTUnwrap(Soundscape.find("rain-on-glass"))))
        XCTAssertTrue(store.canPlay(try XCTUnwrap(Soundscape.find("gentle-rain"))))
    }

    @MainActor
    func testTrialExpiryDoesNotPresentThePaywallByItself() async throws {
        let store = makeAccessStore(trialStart: freemiumNow)
        XCTAssertFalse(store.showPaywall)
        let plus = try XCTUnwrap(Soundscape.find("rain-on-glass"))
        store.play(plus)
        XCTAssertEqual(store.state, .loading)
        XCTAssertFalse(store.showPaywall)
        store.updateTrialClock(now: freemiumNow.addingTimeInterval(8 * 86_400))
        XCTAssertEqual(store.trialDaysRemaining, 0)
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.state, .idle)
        XCTAssertNil(store.currentID)
        XCTAssertTrue(store.canPlay(try XCTUnwrap(Soundscape.find("gentle-rain"))))
        XCTAssertFalse(store.canPlay(plus))
        await store.refreshAccess(now: freemiumNow.addingTimeInterval(9 * 86_400))
        XCTAssertFalse(store.showPaywall)
        XCTAssertFalse(store.hasPremiumAccess)
    }
}

private let freemiumNow = Date(timeIntervalSince1970: 1_700_000_000)

private func expiredTrialStart(now: Date = freemiumNow) -> Date {
    now.addingTimeInterval(-8 * 86_400)
}

@MainActor
private func makeAccessStore(
    trialStart: Date,
    purchased: Bool = false,
    restore: (() async throws -> Bool)? = nil
) -> DriftStore {
    let name = "DriftSleepTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return DriftStore(
        defaults: defaults,
        trialStart: trialStart,
        initiallyPurchased: purchased,
        scriptedRestore: restore,
        useLiveStore: false,
        now: freemiumNow
    )
}

private func writeSilentWav(to url: URL, seconds: Double, sampleRate: UInt32 = 16_000) throws {
    let channels: UInt16 = 1
    let bitsPerSample: UInt16 = 16
    let frames = Int(seconds * Double(sampleRate))
    let dataSize = frames * Int(channels) * Int(bitsPerSample / 8)
    var header = Data()
    func ascii(_ value: String) { header.append(contentsOf: value.utf8) }
    func u16(_ value: UInt16) {
        var v = value.littleEndian
        withUnsafeBytes(of: v) { header.append(contentsOf: $0) }
    }
    func u32(_ value: UInt32) {
        var v = value.littleEndian
        withUnsafeBytes(of: v) { header.append(contentsOf: $0) }
    }
    ascii("RIFF")
    u32(UInt32(36 + dataSize))
    ascii("WAVE")
    ascii("fmt ")
    u32(16)
    u16(1)
    u16(channels)
    u32(sampleRate)
    u32(sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8)
    u16(channels * bitsPerSample / 8)
    u16(bitsPerSample)
    ascii("data")
    u32(UInt32(dataSize))
    header.append(Data(count: dataSize))
    try header.write(to: url)
}
