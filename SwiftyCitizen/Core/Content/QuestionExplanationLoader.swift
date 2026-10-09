import Foundation

/// A separate, optional explanation dataset keyed by question `stableID`.
/// Loaded from a JSON resource bundled alongside the banks; it never modifies the banks
/// themselves (non-invasive). Absent or malformed datasets decode to nil so banks load
/// identically whether or not explanations exist.
struct QuestionExplanationResource: Codable, Hashable {
    let schemaVersion: Int
    let language: String
    let status: ExplanationStatus
    let explanations: [String: String]
}

/// Documented status values for an explanation dataset. Not a free-form string so the
/// commit-readiness of a dataset is explicit at decode time.
enum ExplanationStatus: String, Codable, Hashable {
    /// AI-generated and NOT commit-ready — human curation is pending.
    case draft = "DRAFT"
}

struct QuestionExplanationLoader {
    let bundle: Bundle

    init(bundle: Bundle = Bundle(for: QuestionBankBundleMarker.self)) {
        self.bundle = bundle
    }

    /// Loads the bundled explanation dataset for a version, if present and valid.
    /// Returns nil when the resource is absent or malformed, keeping banks optional.
    func dataset(for version: USCISTestVersion) -> QuestionExplanationResource? {
        guard let url = resourceURL(for: version),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(QuestionExplanationResource.self, from: data)
    }

    /// Parsed explanation map (stableID -> explanation) for a version, or nil when absent.
    func explanationMap(for version: USCISTestVersion) -> [String: String]? {
        dataset(for: version)?.explanations
    }

    /// Populates `explanation` on questions by stableID. Pure + testable with dummy data.
    /// Questions without a (non-empty) map entry keep their current value.
    static func apply(
        explanationMap: [String: String],
        to questions: [QuestionContent]
    ) -> [QuestionContent] {
        guard !explanationMap.isEmpty else { return questions }
        return questions.map { question in
            guard let explanation = explanationMap[question.stableID], !explanation.isEmpty else {
                return question
            }
            return question.withExplanation(explanation)
        }
    }

    /// Loads the bundled explanation dataset for a version and applies it onto loaded
    /// questions. No-op (returns questions unchanged) when no dataset is present.
    func applyExplanations(_ version: USCISTestVersion, to questions: [QuestionContent]) -> [QuestionContent] {
        guard let explanations = explanationMap(for: version), !explanations.isEmpty else {
            return questions
        }
        return QuestionExplanationLoader.apply(explanationMap: explanations, to: questions)
    }

    private func resourceURL(for version: USCISTestVersion) -> URL? {
        let resourceName = explanationResourceName(for: version)
        return bundle.url(forResource: resourceName, withExtension: "json")
                ?? bundle.url(
                    forResource: resourceName,
                    withExtension: "json",
                    subdirectory: "Resources/QuestionBanks"
                )
    }

    private func explanationResourceName(for version: USCISTestVersion) -> String {
        switch version {
        case .twoThousandEight: "uscis-2008-explanations"
        case .twoThousandTwentyFive: "uscis-2025-explanations"
        case .sixtyFiveTwenty: "uscis-65-20-explanations"
        }
    }
}
