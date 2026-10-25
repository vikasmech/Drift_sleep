import Foundation

enum TrialPolicy {
    static let length: TimeInterval = 7 * 24 * 60 * 60

    static func end(start: Date) -> Date {
        start.addingTimeInterval(length)
    }

    static func isActive(start: Date, now: Date) -> Bool {
        now < end(start: start)
    }

    /// Whole days left, rounded up, so the first moment reads as 7 and the last hours read as 1.
    static func daysRemaining(start: Date, now: Date) -> Int {
        let left = end(start: start).timeIntervalSince(now)
        guard left > 0 else { return 0 }
        return Int(ceil(left / 86_400))
    }
}

enum PaywallPolicy {
    /// The purchase screen appears on its own only after the preview has ended, and only until it is dismissed.
    static func shouldPresentAutomatically(isPurchased: Bool, trialDaysRemaining: Int, dismissedAfterTrial: Bool) -> Bool {
        !isPurchased && trialDaysRemaining == 0 && !dismissedAfterTrial
    }
}

enum PlaybackPolicy {
    static func canPlay(isFreeSound: Bool, hasPlusAccess: Bool) -> Bool {
        isFreeSound || hasPlusAccess
    }

    static func isLoopable(isFreeSound: Bool, isPurchased: Bool) -> Bool {
        isFreeSound || isPurchased
    }

    static func loopCount(isFreeSound: Bool, isPurchased: Bool, looping: Bool) -> Int {
        isLoopable(isFreeSound: isFreeSound, isPurchased: isPurchased) && looping ? -1 : 0
    }
}
