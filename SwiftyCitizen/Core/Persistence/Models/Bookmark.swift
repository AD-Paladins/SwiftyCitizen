import Foundation
import SwiftData

/// A learner's "review later" marker for a single question.
///
/// Independent of `StudySession`: it captures a global learner preference for which
/// questions to revisit, scoped by test version. One row per (question, version) pair.
@Model
final class Bookmark {
    var questionStableID: String
    var testVersionRawValue: String
    var createdAt: Date

    init(questionStableID: String, testVersion: USCISTestVersion, createdAt: Date = .now) {
        self.questionStableID = questionStableID
        self.testVersionRawValue = testVersion.rawValue
        self.createdAt = createdAt
    }
}
