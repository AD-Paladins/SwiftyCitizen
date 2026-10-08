import Foundation
import Observation
import SwiftUI

/// Drives a deep link from the Home dashboard into the targeted-review flow.
///
/// Home cannot push onto the Study tab's `NavigationStack`, so it records the scope the
/// learner wants to land on. `StudyView` turns that into a navigation, and
/// `TargetedReviewView` consumes the pending scope on appear and clears it.
@MainActor
@Observable
final class PendingNavigation {
    /// When non-nil, the Study tab should push targeted review, and that view should open
    /// with this scope selected instead of the default `.due`.
    var reviewScope: ReviewScope?

    /// When non-nil, targeted review should open filtered to this topic (from Progress's
    /// coverage map). The domain builder already filters by topic via its category filter, so
    /// the view maps this onto a single selected category.
    var scopedTopic: String?

    func setBookmarked() {
        reviewScope = .bookmarked
    }

    func setScopedTopic(_ topic: String) {
        scopedTopic = topic
    }

    func clear() {
        reviewScope = nil
        scopedTopic = nil
    }
}

/// Tracks whether a study/practice session is currently on screen so the tab bar can
/// confirm before switching tabs (which would otherwise discard the running session).
///
/// Session views mark themselves active on appear/inactive on disappear. `MainTabView`
/// observes `isActive` and, on a tab change while active, confirms before leaving.
@MainActor
@Observable
final class SessionActivityCoordinator {
    private(set) var isActive = false

    func setActive(_ value: Bool) {
        isActive = value
    }
}
