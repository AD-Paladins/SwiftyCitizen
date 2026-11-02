import Foundation

public enum OnboardingConfigurationError: Error, Equatable {
    case missingFilingDate
    case filingDateInFuture
    case missingTestVersion
    case disclaimerNotAccepted
    case selectedVersionDoesNotMatchFilingDate(expected: USCISTestVersion, actual: USCISTestVersion)
}

public struct OnboardingConfiguration: Codable, Hashable {
    public static let testVersionChangeDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2025, month: 10, day: 20).date!

    public var filingDate: Date?
    public var selectedTestVersion: USCISTestVersion?
    public var isSixtyFiveTwentyEligible: Bool
    public var disclaimerAccepted: Bool
    public var shuffleQuestions: Bool
    public var dailyReviewGoal: Int = 15

    public var derivedTestVersion: USCISTestVersion? {
        if isSixtyFiveTwentyEligible {
            return .sixtyFiveTwenty
        }

        guard let filingDate else { return nil }
        return filingDate < Self.testVersionChangeDate ? .twoThousandEight : .twoThousandTwentyFive
    }

    public var testConfiguration: TestConfiguration? {
        guard let selectedTestVersion else { return nil }
        return TestConfiguration.all.first { $0.version == selectedTestVersion }
    }

    public func validationError(asOf currentDate: Date = Date()) -> OnboardingConfigurationError? {
        guard let filingDate else { return .missingFilingDate }
        guard filingDate <= currentDate else { return .filingDateInFuture }
        guard let selectedTestVersion else { return .missingTestVersion }
        guard disclaimerAccepted else { return .disclaimerNotAccepted }

        if let expectedVersion = derivedTestVersion, expectedVersion != selectedTestVersion {
            return .selectedVersionDoesNotMatchFilingDate(expected: expectedVersion, actual: selectedTestVersion)
        }

        return nil
    }

    public var isValid: Bool {
        validationError() == nil
    }
}
