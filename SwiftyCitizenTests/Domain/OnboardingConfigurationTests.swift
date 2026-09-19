//
//  OnboardingConfigurationTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/19/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct OnboardingConfigurationTests {

    @Test
    func derivedVersionIsTwentyTwentyFiveForRecentFiling() {
        let config = validConfig(filingDate: recentFiling)
        #expect(config.derivedTestVersion == .twoThousandTwentyFive)
    }

    @Test
    func derivedVersionIsTwoThousandEightForOldFiling() {
        let config = validConfig(filingDate: oldFiling)
        #expect(config.derivedTestVersion == .twoThousandEight)
    }

    @Test
    func derivedVersionIsSixtyFiveTwentyWhenEligible() {
        let config = OnboardingConfiguration(
            filingDate: recentFiling,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: true,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.derivedTestVersion == .sixtyFiveTwenty)
    }

    @Test
    func derivedVersionIsNilWithoutFilingDate() {
        let config = OnboardingConfiguration(
            filingDate: nil,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.derivedTestVersion == nil)
    }

    @Test
    func testConfigurationResolvesFromSelectedVersion() {
        let config = validConfig(filingDate: recentFiling)
        #expect(config.testConfiguration?.version == .twoThousandTwentyFive)
        #expect(config.testConfiguration?.maximumQuestionsAsked == 20)
    }

    @Test
    func testConfigurationIsNilWhenVersionUnselected() {
        let config = OnboardingConfiguration(
            filingDate: recentFiling,
            selectedTestVersion: nil,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.testConfiguration == nil)
    }

    @Test
    func validationPassesWhenComplete() {
        let config = validConfig(filingDate: recentFiling)
        #expect(config.validationError() == nil)
        #expect(config.isValid)
    }

    @Test
    func validationFailsOnMissingFilingDate() {
        let config = OnboardingConfiguration(
            filingDate: nil,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.validationError() == .missingFilingDate)
        #expect(!config.isValid)
    }

    @Test
    func validationFailsOnFutureFilingDate() {
        let config = OnboardingConfiguration(
            filingDate: futureFiling,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.validationError() == .filingDateInFuture)
    }

    @Test
    func validationFailsOnMissingVersion() {
        let config = OnboardingConfiguration(
            filingDate: recentFiling,
            selectedTestVersion: nil,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.validationError() == .missingTestVersion)
    }

    @Test
    func validationFailsOnMissingLanguage() {
        let config = OnboardingConfiguration(
            filingDate: recentFiling,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: nil,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.validationError() == .missingStudyLanguage)
    }

    @Test
    func validationFailsOnUnacceptedDisclaimer() {
        let config = OnboardingConfiguration(
            filingDate: recentFiling,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: false,
            shuffleQuestions: false
        )
        #expect(config.validationError() == .disclaimerNotAccepted)
    }

    @Test
    func validationFailsOnVersionMismatch() {
        // Recent filing derives 2025, but 2008 is selected.
        let config = OnboardingConfiguration(
            filingDate: recentFiling,
            selectedTestVersion: .twoThousandEight,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
        #expect(config.validationError() == .selectedVersionDoesNotMatchFilingDate(
            expected: .twoThousandTwentyFive,
            actual: .twoThousandEight
        ))
    }

    private var recentFiling: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    }

    private var oldFiling: Date {
        Calendar.current.date(byAdding: .year, value: -10, to: Date())!
    }

    private var futureFiling: Date {
        Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    }

    private func validConfig(filingDate: Date) -> OnboardingConfiguration {
        OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
    }
}
