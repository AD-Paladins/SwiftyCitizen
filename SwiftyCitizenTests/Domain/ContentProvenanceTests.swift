//
//  ContentProvenanceTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct ContentProvenanceTests {

    private func question(
        id: String,
        sourceURL: URL?,
        sourceRevision: String,
        verificationDate: Date?
    ) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What is the supreme law of the land?",
            acceptedAnswerVariants: ["The Constitution"],
            answerCardinality: .exactly(1),
            topic: "Government",
            sourceURL: sourceURL,
            sourceRevision: sourceRevision,
            verificationDate: verificationDate,
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    @Test func emptyBankHasNoProvenance() {
        let provenance = ContentProvenance.extract(from: [])
        #expect(provenance.sourceURL == nil)
        #expect(provenance.sourceRevision == nil)
        #expect(provenance.verificationDate == nil)
        #expect(provenance.referenceCount == 0)
    }

    @Test func singleSourceBankReportsOneReference() {
        let url = URL(string: "https://www.uscis.gov/questions")!
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let questions = [
            question(id: "a", sourceURL: url, sourceRevision: "M-1778 (09/25)", verificationDate: date),
            question(id: "b", sourceURL: url, sourceRevision: "M-1778 (09/25)", verificationDate: date),
        ]
        let provenance = ContentProvenance.extract(from: questions)
        #expect(provenance.sourceURL == url)
        #expect(provenance.sourceRevision == "M-1778 (09/25)")
        #expect(provenance.verificationDate == date)
        #expect(provenance.referenceCount == 1)
    }

    @Test func whitespaceOnlyRevisionDifferenceIsSameReference() {
        // Grouping ignores surrounding whitespace, so a duplicated revision with padding is one
        // reference — matching the loader's validation trimming.
        let url = URL(string: "https://www.uscis.gov/questions")!
        let questions = [
            question(id: "a", sourceURL: url, sourceRevision: "rev. 01/19", verificationDate: nil),
            question(id: "b", sourceURL: url, sourceRevision: "  rev. 01/19  ", verificationDate: nil),
        ]
        let provenance = ContentProvenance.extract(from: questions)
        #expect(provenance.referenceCount == 1)
    }

    @Test func divergentSourcesReportTrueReferenceCount() {
        // Honest fallback: when questions come from different references the count reflects it so
        // the UI can surface "N references" instead of picking one arbitrarily.
        let urlA = URL(string: "https://www.uscis.gov/a")!
        let urlB = URL(string: "https://www.uscis.gov/b")!
        let questions = [
            question(id: "a", sourceURL: urlA, sourceRevision: "rev A", verificationDate: nil),
            question(id: "b", sourceURL: urlB, sourceRevision: "rev B", verificationDate: nil),
        ]
        let provenance = ContentProvenance.extract(from: questions)
        #expect(provenance.referenceCount == 2)
    }

    @Test func missingMetadataDoesNotCrashAndReportsFirstValues() {
        // A question lacking source metadata doesn't break extraction; the bank's first question's
        // values are reported and the count reflects every distinct tuple present.
        let url = URL(string: "https://www.uscis.gov/questions")!
        let questions = [
            question(id: "a", sourceURL: url, sourceRevision: "rev", verificationDate: nil),
            question(id: "b", sourceURL: nil, sourceRevision: "", verificationDate: nil),
        ]
        let provenance = ContentProvenance.extract(from: questions)
        #expect(provenance.sourceURL == url)
        #expect(provenance.referenceCount == 2)
    }
}
