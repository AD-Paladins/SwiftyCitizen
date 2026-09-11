import Foundation

enum USCISTestVersion: String, Codable, CaseIterable, Hashable {
    case twoThousandEight = "2008"
    case twoThousandTwentyFive = "2025"
    case sixtyFiveTwenty = "65/20"

    var displayName: String {
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

enum TestApplicability: Codable, Hashable {
    case filingBeforeOctober20th2025
    case filingOnOrAfterOctober20th2025
    case age65AndResidency20Years

    var summary: String {
        switch self {
        case .filingBeforeOctober20th2025:
            "N-400 filed before October 20, 2025"
        case .filingOnOrAfterOctober20th2025:
            "N-400 filed on or after October 20, 2025"
        case .age65AndResidency20Years:
            "Applicant is age 65 or older and has been a lawful permanent resident for at least 20 years"
        }
    }
}

struct TestConfiguration: Codable, Hashable, Identifiable {
    let version: USCISTestVersion
    let questionBankCount: Int
    let maximumQuestionsAsked: Int
    let passingScore: Int
    let applicability: TestApplicability

    var id: USCISTestVersion { version }

    static let twoThousandEight = TestConfiguration(
        version: .twoThousandEight,
        questionBankCount: 100,
        maximumQuestionsAsked: 10,
        passingScore: 6,
        applicability: .filingBeforeOctober20th2025
    )

    static let twoThousandTwentyFive = TestConfiguration(
        version: .twoThousandTwentyFive,
        questionBankCount: 128,
        maximumQuestionsAsked: 20,
        passingScore: 12,
        applicability: .filingOnOrAfterOctober20th2025
    )

    static let sixtyFiveTwenty = TestConfiguration(
        version: .sixtyFiveTwenty,
        questionBankCount: 20,
        maximumQuestionsAsked: 10,
        passingScore: 6,
        applicability: .age65AndResidency20Years
    )

    static let all: [TestConfiguration] = [
        .twoThousandEight,
        .twoThousandTwentyFive,
        .sixtyFiveTwenty
    ]
}