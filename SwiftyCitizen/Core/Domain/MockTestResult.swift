import Foundation

/// Pure, Foundation-only result of a completed mock test.
///
/// The Progress view reconstructs these primitives from the persisted `StudySession` (`asked` =
/// `deckStableIDs.count`, skipped questions excluded; `correct` = answers whose `wasCorrect` is
/// true), then hands them here. This type owns only the score / pass arithmetic so it stays
/// unit-testable without SwiftData or SwiftUI.
struct MockTestResult: Equatable {
    /// Questions asked — the deck size (`deckStableIDs.count`). Skipped questions are excluded.
    let asked: Int
    /// Mock answers marked correct (`wasCorrect == true`).
    let correct: Int
    /// Passing score for the version (from `TestConfiguration`).
    let passingScore: Int

    /// Official pass/fail: at least `passingScore` of the asked questions answered correctly.
    var passed: Bool {
        correct >= passingScore
    }
}
