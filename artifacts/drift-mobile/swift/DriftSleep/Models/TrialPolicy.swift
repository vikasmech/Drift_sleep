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
