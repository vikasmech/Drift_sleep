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
        XCTAssertEqual(GuidedSession.all.map(\.id), ["little-space", "room-to-rest", "nothing-more-tonight"])
        XCTAssertEqual(GuidedSession.all.map(\.practice), ["NSDR", "NSDR", "Yoga Nidra"])
        XCTAssertEqual(GuidedSession.all.map(\.duration), [600, 1200, 1200])
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
}
