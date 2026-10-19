import Foundation
import SwiftData

@Model
final class SavedOnboardingConfiguration {
    var filingDate: Date
    var selectedTestVersionRawValue: String
    var isSixtyFiveTwentyEligible: Bool
    var disclaimerAccepted: Bool
    var shuffleQuestions: Bool?
    var dailyReviewGoal: Int = 15

    init(configuration: OnboardingConfiguration) {
        precondition(configuration.isValid, "Only valid onboarding configurations can be persisted")
        self.filingDate = configuration.filingDate!
        self.selectedTestVersionRawValue = configuration.selectedTestVersion!.rawValue
        self.isSixtyFiveTwentyEligible = configuration.isSixtyFiveTwentyEligible
        self.disclaimerAccepted = configuration.disclaimerAccepted
        self.shuffleQuestions = configuration.shuffleQuestions
        self.dailyReviewGoal = configuration.dailyReviewGoal
    }

    func update(from configuration: OnboardingConfiguration) {
        precondition(configuration.isValid, "Only valid onboarding configurations can be persisted")
        self.filingDate = configuration.filingDate!
        self.selectedTestVersionRawValue = configuration.selectedTestVersion!.rawValue
        self.isSixtyFiveTwentyEligible = configuration.isSixtyFiveTwentyEligible
        self.disclaimerAccepted = configuration.disclaimerAccepted
        self.shuffleQuestions = configuration.shuffleQuestions
        self.dailyReviewGoal = configuration.dailyReviewGoal
    }

    var configuration: OnboardingConfiguration? {
        guard let selectedTestVersion = USCISTestVersion(rawValue: selectedTestVersionRawValue) else {
            return nil
        }

        return OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: selectedTestVersion,
            isSixtyFiveTwentyEligible: isSixtyFiveTwentyEligible,
            disclaimerAccepted: disclaimerAccepted,
            shuffleQuestions: shuffleQuestions ?? false,
            dailyReviewGoal: dailyReviewGoal
        )
    }
}
