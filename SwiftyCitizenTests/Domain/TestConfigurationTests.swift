//
//  TestConfigurationTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/19/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct TestConfigurationTests {

    @Test
    func twoThousandEightConfiguration() {
        let config = TestConfiguration.twoThousandEight
        #expect(config.version == .twoThousandEight)
        #expect(config.questionBankCount == 100)
        #expect(config.maximumQuestionsAsked == 10)
        #expect(config.passingScore == 6)
        #expect(config.applicability == .filingBeforeOctober20th2025)
    }

    @Test
    func twoThousandTwentyFiveConfiguration() {
        let config = TestConfiguration.twoThousandTwentyFive
        #expect(config.version == .twoThousandTwentyFive)
        #expect(config.questionBankCount == 128)
        #expect(config.maximumQuestionsAsked == 20)
        #expect(config.passingScore == 12)
        #expect(config.applicability == .filingOnOrAfterOctober20th2025)
    }

    @Test
    func sixtyFiveTwentyConfiguration() {
        let config = TestConfiguration.sixtyFiveTwenty
        #expect(config.version == .sixtyFiveTwenty)
        #expect(config.questionBankCount == 20)
        #expect(config.maximumQuestionsAsked == 10)
        #expect(config.passingScore == 6)
        #expect(config.applicability == .age65AndResidency20Years)
    }

    @Test
    func allContainsEveryVersion() {
        #expect(TestConfiguration.all.map(\.version) == [.twoThousandEight, .twoThousandTwentyFive, .sixtyFiveTwenty])
        #expect(TestConfiguration.all.count == 3)
    }

    @Test
    func idMapsToVersion() {
        #expect(TestConfiguration.twoThousandTwentyFive.id == .twoThousandTwentyFive)
    }

    @Test
    func versionsHaveDisplayNames() {
        #expect(USCISTestVersion.twoThousandEight.displayName == "2008 civics test")
        #expect(USCISTestVersion.twoThousandTwentyFive.displayName == "2025 civics test")
        #expect(USCISTestVersion.sixtyFiveTwenty.displayName == "65/20 special consideration")
    }
}
