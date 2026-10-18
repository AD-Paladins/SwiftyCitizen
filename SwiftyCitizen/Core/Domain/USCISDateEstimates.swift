import Foundation

/// Pure domain helpers for estimating dates in the N-400 → interview timeline.
enum USCISDateEstimates {
    /// Estimates the USCIS interview date as exactly six months after the filing date.
    ///
    /// This is a placeholder assumption, not a real USCIS figure. Actual interview timing varies
    /// by field office and current processing load, so this fixed offset should be treated as a
    /// rough "target month" only (see the H1 card that surfaces it).
    // ponytail: fixed 6-month offset; replace with a lookup keyed by field office against published
    // USCIS processing windows once that data is available.
    static func estimatedInterviewDate(
        filingDate: Date?,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        guard let filingDate else { return nil }
        // `asOf` is accepted so the signature matches a future real-data source that depends on the
        // current date; the estimate itself is purely a function of the filing date.
        _ = now
        return calendar.date(byAdding: .month, value: 6, to: filingDate)
    }
}
