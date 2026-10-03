//
//  QuestionExplanationLoaderTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct QuestionExplanationLoaderTests {

    // MARK: apply (pure population logic)

    @Test
    func applyPopulatesExplanationByStableID() {
        let questions = [
            sampleQuestion(id: "2025-001", explanation: nil),
            sampleQuestion(id: "2025-002", explanation: nil),
        ]
        let map = ["2025-001": "Congress writes the laws."]
        let result = QuestionExplanationLoader.apply(explanationMap: map, to: questions)
        #expect(result[0].explanation == "Congress writes the laws.")
        #expect(result[1].explanation == nil)
    }

    @Test
    func applyLeavesUnmappedQuestionsUnchanged() {
        let original = sampleQuestion(id: "2025-009", explanation: nil)
        let result = QuestionExplanationLoader.apply(explanationMap: ["2025-001": "x"], to: [original])
        #expect(result[0].explanation == nil)
        #expect(result[0].stableID == "2025-009")
    }

    @Test
    func applySkipsEmptyExplanationValues() {
        let original = sampleQuestion(id: "2025-001", explanation: nil)
        let result = QuestionExplanationLoader.apply(explanationMap: ["2025-001": ""], to: [original])
        #expect(result[0].explanation == nil)
    }

    @Test
    func applyPreservesExistingExplanationWhenNoMapEntry() {
        let original = sampleQuestion(id: "2025-001", explanation: "Pre-existing.")
        let result = QuestionExplanationLoader.apply(explanationMap: ["2025-002": "other"], to: [original])
        #expect(result[0].explanation == "Pre-existing.")
    }

    @Test
    func applyIgnoresEmptyMap() {
        let original = sampleQuestion(id: "2025-001", explanation: nil)
        let result = QuestionExplanationLoader.apply(explanationMap: [:], to: [original])
        #expect(result[0].explanation == nil)
    }

    // MARK: decoding (dummy data)

    @Test
    func datasetDecodesDraftStatusLanguageAndExplanations() throws {
        let json = """
        {
          "schemaVersion": 1,
          "language": "en",
          "status": "DRAFT",
          "explanations": { "2025-001": "Draft explanation." }
        }
        """
        let data = try #require(json.data(using: .utf8))
        let resource = try JSONDecoder().decode(QuestionExplanationResource.self, from: data)
        #expect(resource.schemaVersion == 1)
        #expect(resource.language == "en")
        #expect(resource.status == .draft)
        #expect(resource.explanations["2025-001"] == "Draft explanation.")
    }

    @Test
    func draftStatusHasDocumentedRawValue() {
        #expect(ExplanationStatus.draft.rawValue == "DRAFT")
    }

    @Test
    func missingDatasetForVersionDecodesToNil() {
        // The 2008 bank has no explanation dataset in this pilot; loading must return nil
        // so banks load identically whether or not explanations exist (graceful + optional).
        let loader = QuestionExplanationLoader()
        #expect(loader.dataset(for: .twoThousandEight) == nil)
    }

    @Test
    func realBundled2025DatasetLoads() throws {
        // End-to-end: the committed pilot file is bundled and discovered by the loader.
        let loader = QuestionExplanationLoader()
        let map = try #require(loader.explanationMap(for: .twoThousandTwentyFive))
        #expect(map["2025-001"] != nil)
        #expect(map["2025-025"] != nil)
        #expect(map.count == 25)
    }

    // MARK: applyExplanations (orchestration)

    @Test
    func applyExplanationsIsNoOpWhenDatasetAbsent() {
        // 2008 has no explanation dataset in this pilot, so applying it must be a no-op.
        let original = sampleQuestion(id: "2008-001", explanation: nil)
        let loader = QuestionExplanationLoader()
        let result = loader.applyExplanations(.twoThousandEight, to: [original])
        #expect(result[0].explanation == nil)
    }

    private func sampleQuestion(id: String, explanation: String?) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What is \(id)?",
            acceptedAnswerVariants: ["An answer"],
            answerCardinality: .exactly(1),
            topic: "Government",
            sourceURL: URL(string: "https://www.uscis.gov")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false,
            explanation: explanation
        )
    }
}
