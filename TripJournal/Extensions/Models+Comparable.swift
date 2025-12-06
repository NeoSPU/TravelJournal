import Foundation

extension Trip: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.startDate < rhs.startDate
    }
}

extension Event: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }
}
