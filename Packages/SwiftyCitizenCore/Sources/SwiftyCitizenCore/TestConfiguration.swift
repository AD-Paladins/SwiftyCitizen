import Foundation

public enum USCISTestVersion: String, Codable, CaseIterable, Hashable {
    case twoThousandEight = "2008"
    case twoThousandTwentyFive = "2025"
    case sixtyFiveTwenty = "65/20"

    public var displayName: String {
        switch self {
        case .twoThousandEight:
            "2008 civics test"
        case .twoThousandTwentyFive:
            "2025 civics test"
        case .sixtyFiveTwenty:
            "65/20 special consideration"
        }
    }
}

public enum TestApplicability: Codable, Hashable {
    case filingBeforeOctober20th2025
    case filingOnOrAfterOctober20th2025
    case age65AndResidency20Years
}

public struct TestConfiguration: Codable, Hashable, Identifiable {
    public let version: USCISTestVersion
    public let questionBankCount: Int
    public let maximumQuestionsAsked: Int
    public let passingScore: Int
    public let applicability: TestApplicability

    public var id: USCISTestVersion { version }

    public var passingPercentage: Double? {
        guard maximumQuestionsAsked > 0 else { return nil }
        return Double(passingScore) / Double(maximumQuestionsAsked)
    }

    public static let twoThousandEight = TestConfiguration(
        version: .twoThousandEight,
        questionBankCount: 100,
        maximumQuestionsAsked: 10,
        passingScore: 6,
        applicability: .filingBeforeOctober20th2025
    )

    public static let twoThousandTwentyFive = TestConfiguration(
        version: .twoThousandTwentyFive,
        questionBankCount: 128,
        maximumQuestionsAsked: 20,
        passingScore: 12,
        applicability: .filingOnOrAfterOctober20th2025
    )

    public static let sixtyFiveTwenty = TestConfiguration(
        version: .sixtyFiveTwenty,
        questionBankCount: 20,
        maximumQuestionsAsked: 10,
        passingScore: 6,
        applicability: .age65AndResidency20Years
    )

    public static let all: [TestConfiguration] = [
        .twoThousandEight,
        .twoThousandTwentyFive,
        .sixtyFiveTwenty
    ]

    /// Daily-review goal presets linked to the question bank. The 65/20 set (20 questions) caps at
    /// 20; the larger banks keep the standard set. Shared here so Settings and Home agree.
    public static func dailyGoalPresets(for version: USCISTestVersion) -> [Int] {
        switch version {
        case .sixtyFiveTwenty:
            [5, 10, 15, 20]
        default:
            [15, 25, 30, 45, 60]
        }
    }
}