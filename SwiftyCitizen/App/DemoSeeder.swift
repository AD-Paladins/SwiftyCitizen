import Foundation
import SwiftData

enum DemoSeeder {
    static func seedIfNeeded(in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<SavedOnboardingConfiguration>())
        guard existing.isEmpty else { return }
        guard let configuration = seedConfiguration() else { return }
        context.insert(SavedOnboardingConfiguration(configuration: configuration))
        try context.save()
    }

    static func seedConfiguration() -> OnboardingConfiguration? {
        var components = DateComponents(calendar: Calendar(identifier: .gregorian))
        components.year = 2024
        components.month = 1
        components.day = 15
        guard let filingDate = components.date else { return nil }

        return OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: .twoThousandEight,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        )
    }
}
