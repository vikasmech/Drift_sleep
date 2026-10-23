import Foundation

struct GuidedSegment: Equatable {
    let start: TimeInterval
    let text: String
}

struct GuidedSession: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let practice: String
    let duration: TimeInterval
    let segments: [GuidedSegment]
    let recording: String?

    var recordingURL: URL? {
        guard let recording else { return nil }
        let bundle = Bundle.main
        let candidates = [
            bundle.url(forResource: recording, withExtension: "mp3"),
            bundle.url(forResource: recording, withExtension: "mp3", subdirectory: "Resources"),
            bundle.bundleURL.appendingPathComponent("\(recording).mp3"),
            bundle.bundleURL.appendingPathComponent("Resources/\(recording).mp3")
        ]
        return candidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    var minutes: Int { Int(duration / 60) }

    static func find(_ id: String) -> GuidedSession? { all.first { $0.id == id } }

    static let all: [GuidedSession] = [littleSpace, nothingMoreTonight]

    private static let littleSpace = GuidedSession(
        id: "little-space",
        title: "A little space",
        detail: "Ten quiet minutes of guided rest, with a gentle return.",
        practice: "NSDR",
        duration: 600,
        segments: [
            .init(start: 0, text: "Welcome to Drift. These next few minutes are for resting, without needing to fall asleep. Choose a safe place where you can lie down or sit with support. Not while driving. Let your eyes close if that feels comfortable, or leave them softly open. Nothing needs to be achieved."),
            .init(start: 60, text: "You can change position or stop at any time. If looking inward feels uncomfortable, listen to the sounds in the room instead. Feel where the surface beneath you meets your body. Let it take some of your weight. You do not need to make yourself completely still."),
            .init(start: 120, text: "Notice that breathing is already happening. There is no count to follow and no need for a deeper breath. Perhaps you feel movement around your ribs, or your belly, or the air near your nose. Choose whichever is easiest to notice. Let the next breath find its own pace."),
            .init(start: 180, text: "Bring a little attention to your forehead. Then your eyes, your cheeks, and the space around your mouth. You might allow your jaw a little room. Notice your shoulders without asking them to change. If softening comes, let it come. If it does not, you can still rest."),
            .init(start: 240, text: "Feel your right arm, from the shoulder down to the hand. Notice your palm and fingertips. Now your left arm, your palm and fingertips. Perhaps there is warmth, contact, or very little sensation. Any of these is fine. Let both hands be where they are."),
            .init(start: 300, text: "Notice your back against its support. Your hips. Your right thigh, lower leg and foot. Your left thigh, lower leg and foot. There is no correct sensation to find. Simply include these parts of you in your attention, then let the effort of noticing become a little lighter."),
            .init(start: 360, text: "If it feels comfortable, sense your body as a whole. A body resting here, with breathing moving through it. You do not have to hold every part in awareness. Let the room, the surface beneath you, and your body all belong to this moment."),
            .init(start: 420, text: "For a little while, there will be fewer words. Thoughts may arrive. You do not need to finish them or push them away. Whenever you notice that you have wandered, return to a point of contact beneath you, or to an ordinary breath. Begin again as gently as you can."),
            .init(start: 480, text: "There is no score for this rest. Being distracted does not mean you have done it wrong. Notice one thing that is here now: a sound, the touch of clothing, or the movement of a breath. Let that be enough for the next few moments."),
            .init(start: 540, text: "Begin to notice more of the room around you. Feel your fingers and toes, and move them if you wish. Let your eyes open when you are ready. Before sitting or standing, take your time and check how you feel. This session is ending. You can return to your day at your own pace.")
        ],
        recording: "nsdr"
    )

    private static let nothingMoreTonight = GuidedSession(
        id: "nothing-more-tonight",
        title: "Nothing more tonight",
        detail: "A bedtime Yoga Nidra that ends quietly, without a wake-up cue.",
        practice: "Yoga Nidra",
        duration: 1200,
        segments: [
            .init(start: 0, text: "Welcome to Drift. This is a gentle Yoga Nidra practice for winding down at bedtime. Settle in a safe place where you can rest without needing to drive or do anything demanding. Arrange your pillow, blanket, or other support. Let your eyes close if that feels right. They can stay open too. You can move, change an instruction, or stop whenever you wish."),
            .init(start: 120, text: "Notice where your body meets the bed or the surface beneath you. There is no need to press down or become heavier. Just notice the support that is already here. If you would like, choose a simple intention for this time. Perhaps, for now, I can rest. Or use words of your own. Say them quietly to yourself once, without needing to make them come true."),
            .init(start: 240, text: "Let attention move through the right hand. The thumb. First finger. Middle finger. Ring finger. Little finger. The palm of the hand. The back of the hand. The wrist. Lower arm. Elbow. Upper arm. Right shoulder. You are not being asked to move these places, only to notice or think of them. If you lose your place, return wherever the next words meet you."),
            .init(start: 360, text: "Now the left hand. The thumb. First finger. Middle finger. Ring finger. Little finger. The palm. The back of the hand. Left wrist. Lower arm. Elbow. Upper arm. Left shoulder. Both arms resting. Both hands resting. You do not need to hold all of this in your attention. One place at a time is enough."),
            .init(start: 480, text: "Bring attention to the right foot. The toes. The sole. The heel. Right ankle. Lower leg. Knee. Thigh. Then the left foot. The toes. The sole. The heel. Left ankle. Lower leg. Knee. Thigh. Both legs, supported. If sensation is unclear, you can simply picture the area or silently hear its name. There is nothing to get right."),
            .init(start: 600, text: "Notice the back of your body: the places around your hips, your lower back, your upper back. Then the front of your body, only if that feels comfortable. Your belly. Your ribs. Your shoulders. Your neck. Your jaw. Your cheeks. Your eyes. Your forehead. Let attention become less precise now. You can return to your hands or the sounds around you whenever you prefer."),
            .init(start: 720, text: "Notice an ordinary breath. Perhaps a small movement, perhaps the feeling of air at your nose. Let breathing continue without counting or holding it. Each breath can be different. You do not need to make the next one longer. If following the breath is not restful, feel the pillow or blanket instead. Let one familiar sensation be enough."),
            .init(start: 840, text: "If imagining feels comfortable, picture a quiet room with soft evening light. There is nothing waiting for you there, and nothing you need to arrange. Or let the image go, and feel the real support beneath you. You do not need to see anything clearly. Let words, images, and thoughts pass without needing to follow them to an ending."),
            .init(start: 960, text: "You might return once to the intention you chose. For now, I can rest. Or your own words. Then let even those words become quiet. You do not need to keep listening closely. If you remain awake, that is all right. If sleep arrives, you do not need to resist it. Let this time be rest, without asking it to become anything else."),
            .init(start: 1080, text: "There is nothing more to follow tonight. Feel the support beneath you, if you wish, and let the guidance fall away. There will be quiet now. You do not need to reach for the phone when the recording ends. Rest in whatever way feels comfortable.")
        ],
        recording: "yoga-nidra"
    )
}
