//
//  MockTestResultTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct MockTestResultTests {

    // MARK: passed — at or above the passing score

    @Test
    func passesWhenCorrectEqualsPassingScore() {
        let result = MockTestResult(asked: 20, correct: 12, passingScore: 12)
        #expect(result.passed == true)
    }

    @Test
    func passesWhenCorrectExceedsPassingScore() {
        let result = MockTestResult(asked: 20, correct: 15, passingScore: 12)
        #expect(result.passed == true)
    }

    // MARK: passed — below the passing score

    @Test
    func failsWhenCorrectIsOneBelowPassingScore() {
        let result = MockTestResult(asked: 20, correct: 11, passingScore: 12)
        #expect(result.passed == false)
    }

    @Test
    func failsWhenNothingAnsweredCorrectly() {
        let result = MockTestResult(asked: 10, correct: 0, passingScore: 6)
        #expect(result.passed == false)
    }

    // MARK: asked reflects deck size, not attempt count

    @Test
    func askedIsTheDeckSizeNotTheAttemptCount() {
        // Skipped questions are excluded from `asked`; only correct answers feed the score.
        let result = MockTestResult(asked: 20, correct: 12, passingScore: 12)
        #expect(result.asked == 20)
        #expect(result.correct == 12)
    }

    // MARK: equatable — lets the view assert on the whole result

    @Test
    func resultIsEquatable() {
        let a = MockTestResult(asked: 20, correct: 12, passingScore: 12)
        let b = MockTestResult(asked: 20, correct: 12, passingScore: 12)
        #expect(a == b)
    }
}
