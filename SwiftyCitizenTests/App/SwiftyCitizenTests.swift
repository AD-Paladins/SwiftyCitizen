//
//  SwiftyCitizenTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct SwiftyCitizenTests {

    @Test
    func filingDateSelectsApplicableVersion() {
        let beforeChange = OnboardingConfiguration(
            filingDate: date(year: 2025, month: 10, day: 19),
            selectedTestVersion: .twoThousandEight,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        let afterChange = OnboardingConfiguration(
            filingDate: date(year: 2025, month: 10, day: 20),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )

        #expect(beforeChange.validationError(asOf: date(year: 2026, month: 1, day: 1)) == nil)
        #expect(afterChange.validationError(asOf: date(year: 2026, month: 1, day: 1)) == nil)
        #expect(beforeChange.derivedTestVersion == .twoThousandEight)
        #expect(afterChange.derivedTestVersion == .twoThousandTwentyFive)
    }

    @Test
    func sixtyFiveTwentyOverridesFilingDateSelection() {
        let configuration = OnboardingConfiguration(
            filingDate: date(year: 2026, month: 1, day: 1),
            selectedTestVersion: .sixtyFiveTwenty,
            isSixtyFiveTwentyEligible: true,
            studyLanguage: .spanish,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )

        #expect(configuration.validationError(asOf: date(year: 2026, month: 2, day: 1)) == nil)
        #expect(configuration.testConfiguration == .sixtyFiveTwenty)
    }

    @Test
    func incompleteAndMismatchedConfigurationsAreRejected() {
        let incomplete = OnboardingConfiguration(
            filingDate: nil,
            selectedTestVersion: nil,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: nil,
            disclaimerAccepted: false,
            shuffleQuestions: false
        )
        let mismatched = OnboardingConfiguration(
            filingDate: date(year: 2025, month: 11, day: 1),
            selectedTestVersion: .twoThousandEight,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )

        #expect(incomplete.validationError(asOf: date(year: 2026, month: 1, day: 1)) == .missingFilingDate)
        #expect(mismatched.validationError(asOf: date(year: 2026, month: 1, day: 1)) == .selectedVersionDoesNotMatchFilingDate(expected: .twoThousandTwentyFive, actual: .twoThousandEight))
    }

    @Test
    func savedConfigurationRoundTripsThroughSwiftData() throws {
        let modelContainer = try ModelContainer(
            for: SavedOnboardingConfiguration.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)
        let original = OnboardingConfiguration(
            filingDate: date(year: 2024, month: 4, day: 3),
            selectedTestVersion: .twoThousandEight,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .spanish,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )

        context.insert(SavedOnboardingConfiguration(configuration: original))
        try context.save()

        let saved = try context.fetch(FetchDescriptor<SavedOnboardingConfiguration>())
        #expect(saved.count == 1)
        #expect(saved.first?.configuration == original)
    }

    @Test(arguments: TestConfiguration.all)
    func configurationsHaveVerifiedRules(configuration: TestConfiguration) {
        switch configuration.version {
        case .twoThousandEight:
            #expect(configuration.questionBankCount == 100)
            #expect(configuration.maximumQuestionsAsked == 10)
            #expect(configuration.passingScore == 6)
            #expect(configuration.applicability == .filingBeforeOctober20th2025)
        case .twoThousandTwentyFive:
            #expect(configuration.questionBankCount == 128)
            #expect(configuration.maximumQuestionsAsked == 20)
            #expect(configuration.passingScore == 12)
            #expect(configuration.applicability == .filingOnOrAfterOctober20th2025)
        case .sixtyFiveTwenty:
            #expect(configuration.questionBankCount == 20)
            #expect(configuration.maximumQuestionsAsked == 10)
            #expect(configuration.passingScore == 6)
            #expect(configuration.applicability == .age65AndResidency20Years)
        }
    }

    @Test
    func malformedQuestionContentReportsTypedErrors() {
        let question = QuestionContent(
            stableID: "",
            testVersion: .twoThousandTwentyFive,
            officialQuestion: " ",
            acceptedAnswerVariants: [],
            answerCardinality: .exactly(0),
            topic: " ",
            sourceURL: nil,
            sourceRevision: " ",
            verificationDate: nil,
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )

        let result = QuestionContentValidator.validate([question], for: .twoThousandTwentyFive)

        guard case .failure(let failure) = result else {
            Issue.record("Expected malformed question content to fail validation")
            return
        }
        #expect(failure.errors.contains(.invalidQuestionCount(expected: 128, actual: 1)))
        #expect(failure.errors.contains(.emptyID(index: 0)))
        #expect(failure.errors.contains(.invalidAnswerCardinality(id: "")))
        #expect(failure.errors.contains(.missingSourceMetadata(id: "", field: .sourceURL)))
    }

    @Test
    func duplicateIDsAreRejected() {
        let first = makeQuestion(id: "duplicate")
        let second = makeQuestion(id: "duplicate")

        let result = QuestionContentValidator.validate(
            [first, second],
            for: TestConfiguration(
                version: .twoThousandTwentyFive,
                questionBankCount: 2,
                maximumQuestionsAsked: 2,
                passingScore: 1,
                applicability: .filingOnOrAfterOctober20th2025
            )
        )

        guard case .failure(let failure) = result else {
            Issue.record("Expected duplicate IDs to fail validation")
            return
        }
        #expect(failure.errors == [.duplicateID(id: "duplicate")])
    }

    @Test
    func minimalQuestionBankValidates() {
        let configuration = TestConfiguration(
            version: .twoThousandTwentyFive,
            questionBankCount: 2,
            maximumQuestionsAsked: 2,
            passingScore: 1,
            applicability: .filingOnOrAfterOctober20th2025
        )
        let questions = [makeQuestion(id: "one"), makeQuestion(id: "two")]

        let result = QuestionContentValidator.validate(questions, for: configuration)

        guard case .success = result else {
            Issue.record("Expected the minimal question bank to pass validation")
            return
        }
    }

    @Test
    func questionsFromAnotherBankAreRejected() {
        let question = makeQuestion(id: "2008-question", version: .twoThousandEight)

        let result = QuestionContentValidator.validate(
            [question],
            for: TestConfiguration(
                version: .twoThousandTwentyFive,
                questionBankCount: 1,
                maximumQuestionsAsked: 1,
                passingScore: 1,
                applicability: .filingOnOrAfterOctober20th2025
            )
        )

        guard case .failure(let failure) = result else {
            Issue.record("Expected a question from another bank to fail validation")
            return
        }
        #expect(failure.errors.contains(.questionAssignedToWrongBank(
            id: "2008-question",
            expected: .twoThousandTwentyFive,
            actual: .twoThousandEight
        )))
    }

    @Test(arguments: USCISTestVersion.allCases)
    func bundledBanksLoadWithExpectedCounts(version: USCISTestVersion) throws {
        let questions = try QuestionBankLoader().load(version: version)

        #expect(questions.count == TestConfiguration.all.first { $0.version == version }?.questionBankCount)
        #expect(Set(questions.map(\.stableID)).count == questions.count)
        #expect(questions.allSatisfy { $0.testVersion == version })
        #expect(questions.allSatisfy { $0.sourceURL?.host == "www.uscis.gov" })
        #expect(questions.allSatisfy { $0.verificationDate != nil })
    }

    @Test
    func sixtyFiveTwentyLoadsTheOfficialDesignatedSubset() throws {
        let questions = try QuestionBankLoader().load(version: .sixtyFiveTwenty)

        #expect(questions.map(\.stableID) == (1...20).map { String(format: "2008-%03d", $0) })
        #expect(questions.allSatisfy { $0.isSixtyFiveTwentyQuestion })
        #expect(questions.allSatisfy { $0.sourceRevision == "rev. 01/19" })
    }

    @Test
    func currentAndJurisdictionDependentAnswersAreMarked() throws {
        let questions = try QuestionBankLoader().load(version: .twoThousandTwentyFive)

        #expect(questions.contains { $0.stableID == "2025-030" && $0.isJurisdictionDependent })
        #expect(questions.contains { $0.stableID == "2025-038" && $0.isJurisdictionDependent })
        #expect(questions.contains { $0.stableID == "2025-039" && $0.isJurisdictionDependent })
    }

    private func makeQuestion(
        id: String,
        version: USCISTestVersion = .twoThousandTwentyFive
    ) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: version,
            officialQuestion: "What is the supreme law of the land?",
            acceptedAnswerVariants: ["The Constitution"],
            answerCardinality: .exactly(1),
            topic: "Government",
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day))!
    }

}
