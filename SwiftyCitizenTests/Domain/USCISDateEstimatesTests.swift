//
//  USCISDateEstimatesTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 10/18/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct USCISDateEstimatesTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test
    func returnsNilWhenFilingDateIsNil() {
        #expect(USCISDateEstimates.estimatedInterviewDate(filingDate: nil) == nil)
    }

    @Test
    func addsSixMonthsToPastFilingDate() {
        let filing = date(2024, 1, 15)
        let result = USCISDateEstimates.estimatedInterviewDate(filingDate: filing)
        #expect(result != nil)
        let components = calendar.dateComponents([.year, .month, .day], from: result!)
        #expect(components.year == 2024)
        #expect(components.month == 7)
        #expect(components.day == 15)
    }

    @Test
    func clampsToLastDayWhenTargetMonthIsShorter() {
        // March 31 + 6 months lands in September, which has only 30 days.
        let filing = date(2024, 3, 31)
        let result = USCISDateEstimates.estimatedInterviewDate(filingDate: filing)
        let components = calendar.dateComponents([.year, .month, .day], from: result!)
        #expect(components.month == 9)
        #expect(components.day == 30)
    }

    @Test
    func estimateIsIndependentOfAsOf() {
        // The estimate is a pure function of the filing date; a different "now" does not move it.
        let filing = date(2023, 11, 10)
        let asOf = date(2025, 6, 1)
        let result = USCISDateEstimates.estimatedInterviewDate(filingDate: filing, asOf: asOf)
        let components = calendar.dateComponents([.year, .month, .day], from: result!)
        #expect(components.month == 5)
        #expect(components.day == 10)
    }
}
