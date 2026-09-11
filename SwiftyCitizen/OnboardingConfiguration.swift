import Foundation

enum StudyLanguage: String, Codable, CaseIterable, Identifiable {
    case english
    case spanish

    var id: Self { self }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Spanish study support"
        }
    }
}

enum OnboardingConfigurationError: Error, Equatable {
    case missingFilingDate
    case filingDateInFuture
    case missingTestVersion
    case missingStudyLanguage
    case disclaimerNotAccepted
    case selectedVersionDoesNotMatchFilingDate(expected: USCISTestVersion, actual: USCISTestVersion)
}

struct OnboardingConfiguration: Codable, Hashable {
    static let testVersionChangeDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2025, month: 10, day: 20).date!

    var filingDate: Date?
    var selectedTestVersion: USCISTestVersion?
    var isSixtyFiveTwentyEligible: Bool
    var studyLanguage: StudyLanguage?
    var disclaimerAccepted: Bool

    var derivedTestVersion: USCISTestVersion? {
        if isSixtyFiveTwentyEligible {
            return .sixtyFiveTwenty
        }

        guard let filingDate else { return nil }
        return filingDate < Self.testVersionChangeDate ? .twoThousandEight : .twoThousandTwentyFive
    }

    var testConfiguration: TestConfiguration? {
        guard let selectedTestVersion else { return nil }
        return TestConfiguration.all.first { $0.version == selectedTestVersion }
    }

    func validationError(asOf currentDate: Date = Date()) -> OnboardingConfigurationError? {
        guard let filingDate else { return .missingFilingDate }
        guard filingDate <= currentDate else { return .filingDateInFuture }
        guard let selectedTestVersion else { return .missingTestVersion }
        guard studyLanguage != nil else { return .missingStudyLanguage }
        guard disclaimerAccepted else { return .disclaimerNotAccepted }

        if let expectedVersion = derivedTestVersion, expectedVersion != selectedTestVersion {
            return .selectedVersionDoesNotMatchFilingDate(expected: expectedVersion, actual: selectedTestVersion)
        }

        return nil
    }

    var isValid: Bool {
        validationError() == nil
    }
}
