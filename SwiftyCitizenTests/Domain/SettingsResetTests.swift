//
//  SettingsResetTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/26/26.
//

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct SettingsResetTests {

    private let filingDate = Date(timeIntervalSince1970: 1_768_000_000)

    private func makeContainer() -> ModelContainer {
        try! ModelContainer(
            for: SavedOnboardingConfiguration.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeSavedConfiguration() -> SavedOnboardingConfiguration {
        let configuration = OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        return SavedOnboardingConfiguration(configuration: configuration)
    }

    @Test
    func resetDeletesAttemptsAndKeepsConfig() throws {
        let context = ModelContext(makeContainer())

        context.insert(makeSavedConfiguration())
        context.insert(QuestionAttempt(questionStableID: "q1", testVersion: .twoThousandTwentyFive, assessment: .gotIt))
        context.insert(QuestionAttempt(questionStableID: "q2", testVersion: .twoThousandTwentyFive, assessment: .gotIt))
        try? context.save()

        resetSpacedRepetition(context)

        let attempts = try context.fetch(FetchDescriptor<QuestionAttempt>())
        #expect(attempts.count == 0)

        let saved = try context.fetch(FetchDescriptor<SavedOnboardingConfiguration>())
        #expect(saved.count == 1)
        #expect(saved.first?.filingDate == filingDate)
    }

    @Test
    func resetWithNoAttemptsIsNoOp() throws {
        let context = ModelContext(makeContainer())

        context.insert(makeSavedConfiguration())
        try? context.save()

        resetSpacedRepetition(context)

        let attempts = try context.fetch(FetchDescriptor<QuestionAttempt>())
        #expect(attempts.count == 0)

        let saved = try context.fetch(FetchDescriptor<SavedOnboardingConfiguration>())
        #expect(saved.count == 1)
        #expect(saved.first?.filingDate == filingDate)
    }
}
