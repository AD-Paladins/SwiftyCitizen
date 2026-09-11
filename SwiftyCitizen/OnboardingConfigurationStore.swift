import Foundation
import SwiftData

@Model
final class SavedOnboardingConfiguration {
    var filingDate: Date
    var selectedTestVersionRawValue: String
    var isSixtyFiveTwentyEligible: Bool
    var studyLanguageRawValue: String
    var disclaimerAccepted: Bool

    init(configuration: OnboardingConfiguration) {
        precondition(configuration.isValid, "Only valid onboarding configurations can be persisted")
        self.filingDate = configuration.filingDate!
        self.selectedTestVersionRawValue = configuration.selectedTestVersion!.rawValue
        self.isSixtyFiveTwentyEligible = configuration.isSixtyFiveTwentyEligible
        self.studyLanguageRawValue = configuration.studyLanguage!.rawValue
        self.disclaimerAccepted = configuration.disclaimerAccepted
    }

    func update(from configuration: OnboardingConfiguration) {
        precondition(configuration.isValid, "Only valid onboarding configurations can be persisted")
        self.filingDate = configuration.filingDate!
        self.selectedTestVersionRawValue = configuration.selectedTestVersion!.rawValue
        self.isSixtyFiveTwentyEligible = configuration.isSixtyFiveTwentyEligible
        self.studyLanguageRawValue = configuration.studyLanguage!.rawValue
        self.disclaimerAccepted = configuration.disclaimerAccepted
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
            disclaimerAccepted: disclaimerAccepted
        )
    }
}
