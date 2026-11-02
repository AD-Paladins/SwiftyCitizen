import Foundation
import SwiftyCitizenCore

// Bridge: QuestionAttempt is a SwiftData-backed class living in the app target.
// Its domain-derived snapshot type lives in SwiftyCitizenCore. This extension
// keeps the mapping in the app so the domain package stays free of SwiftData.
extension QuestionAttempt {
    var snapshot: StudyAttemptSnapshot? {
        guard let version = USCISTestVersion(rawValue: testVersionRawValue) else { return nil }
        return StudyAttemptSnapshot(
            stableID: questionStableID,
            testVersion: version,
            assessment: assessment,
            wasCorrect: wasCorrect,
            answeredAt: answeredAt,
            boxLevel: boxLevel
        )
    }
}
