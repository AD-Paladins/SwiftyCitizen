import Foundation
import SwiftData

@Model
final class StudySession {
    var modeRawValue: String
    var testVersionRawValue: String
    var startedAt: Date
    var endedAt: Date?
    var attempts: [QuestionAttempt]
    var deckStableIDsRaw: String?
    var currentIndex: Int = 0

    init(
        mode: StudyMode,
        testVersion: USCISTestVersion,
        startedAt: Date = .now,
        deckStableIDs: [String] = []
    ) {
        self.modeRawValue = mode.rawValue
        self.testVersionRawValue = testVersion.rawValue
        self.startedAt = startedAt
        self.endedAt = nil
        self.attempts = []
        self.deckStableIDsRaw = Self.encode(deckStableIDs)
        self.currentIndex = 0
    }

    var mode: StudyMode? {
        StudyMode(rawValue: modeRawValue)
    }

    var testVersion: USCISTestVersion? {
        USCISTestVersion(rawValue: testVersionRawValue)
    }

    var isComplete: Bool {
        endedAt != nil
    }

    var answeredCount: Int {
        attempts.count
    }

    var deckStableIDs: [String] {
        Self.decode(deckStableIDsRaw)
    }

    func applyProgress(answeredIDs: [String], currentIndex: Int) {
        self.currentIndex = currentIndex
        self.deckStableIDsRaw = Self.encode(answeredIDs)
    }

    private static func encode(_ ids: [String]) -> String? {
        guard let data = try? JSONEncoder().encode(ids) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func decode(_ raw: String?) -> [String] {
        guard let raw, let data = raw.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }
}

@Model
final class QuestionAttempt {
    var questionStableID: String
    var testVersionRawValue: String
    var assessmentRawValue: String
    var answerText: String?
    var wasCorrect: Bool?
    var answeredAt: Date
    var session: StudySession?

    init(
        questionStableID: String,
        testVersion: USCISTestVersion,
        assessment: SelfAssessment,
        answeredAt: Date = .now
    ) {
        self.questionStableID = questionStableID
        self.testVersionRawValue = testVersion.rawValue
        self.assessmentRawValue = assessment.rawValue
        self.answerText = nil
        self.wasCorrect = nil
        self.answeredAt = answeredAt
    }

    convenience init(
        questionStableID: String,
        testVersion: USCISTestVersion,
        answerText: String,
        wasCorrect: Bool,
        answeredAt: Date = .now
    ) {
        self.init(
            questionStableID: questionStableID,
            testVersion: testVersion,
            assessment: .gotIt,
            answeredAt: answeredAt
        )
        self.answerText = answerText
        self.wasCorrect = wasCorrect
        self.assessmentRawValue = ""
    }

    var assessment: SelfAssessment? {
        SelfAssessment(rawValue: assessmentRawValue)
    }

    var testVersion: USCISTestVersion? {
        USCISTestVersion(rawValue: testVersionRawValue)
    }

    var flashcardAttemptRecord: FlashcardAttemptRecord? {
        guard let assessment, let testVersion else { return nil }
        return FlashcardAttemptRecord(
            stableID: questionStableID,
            testVersion: testVersion,
            assessment: assessment
        )
    }
}