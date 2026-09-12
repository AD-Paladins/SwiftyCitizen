import Foundation
import SwiftData

@Model
final class SavedOnboardingConfiguration {
    var filingDate: Date
    var selectedTestVersionRawValue: String
    var isSixtyFiveTwentyEligible: Bool
    var studyLanguageRawValue: String
    var disclaimerAccepted: Bool
    var shuffleQuestions: Bool?

    init(configuration: OnboardingConfiguration) {
        precondition(configuration.isValid, "Only valid onboarding configurations can be persisted")
        self.filingDate = configuration.filingDate!
        self.selectedTestVersionRawValue = configuration.selectedTestVersion!.rawValue
        self.isSixtyFiveTwentyEligible = configuration.isSixtyFiveTwentyEligible
        self.studyLanguageRawValue = configuration.studyLanguage!.rawValue
        self.disclaimerAccepted = configuration.disclaimerAccepted
        self.shuffleQuestions = configuration.shuffleQuestions
    }

    func update(from configuration: OnboardingConfiguration) {
        precondition(configuration.isValid, "Only valid onboarding configurations can be persisted")
        self.filingDate = configuration.filingDate!
        self.selectedTestVersionRawValue = configuration.selectedTestVersion!.rawValue
        self.isSixtyFiveTwentyEligible = configuration.isSixtyFiveTwentyEligible
        self.studyLanguageRawValue = configuration.studyLanguage!.rawValue
        self.disclaimerAccepted = configuration.disclaimerAccepted
        self.shuffleQuestions = configuration.shuffleQuestions
    }

    var configuration: OnboardingConfiguration? {
        guard let selectedTestVersion = USCISTestVersion(rawValue: selectedTestVersionRawValue),
              let studyLanguage = StudyLanguage(rawValue: studyLanguageRawValue) else {
            return nil
        }

        return OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: selectedTestVersion,
            isSixtyFiveTwentyEligible: isSixtyFiveTwentyEligible,
            studyLanguage: studyLanguage,
            disclaimerAccepted: disclaimerAccepted,
            shuffleQuestions: shuffleQuestions ?? false
        )
    }
}
