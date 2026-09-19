import Foundation

final class QuestionBankBundleMarker {}

struct QuestionBankResource: Codable, Hashable {
    let schemaVersion: Int
    let version: USCISTestVersion
    let sourceURL: URL
    let sourceRevision: String
    let verificationDate: Date
    let derivedFromVersion: USCISTestVersion?
    let questionIDs: [String]?
    let questions: [QuestionRecord]?

    struct QuestionRecord: Codable, Hashable {
        let stableID: String
        let officialQuestion: String
        let acceptedAnswerVariants: [String]
        let answerCardinality: Int
        let topic: String
        let sourceURL: URL
        let sourceRevision: String
        let verificationDate: Date
        let isJurisdictionDependent: Bool
        let isSixtyFiveTwentyQuestion: Bool

        func question(for version: USCISTestVersion) -> QuestionContent {
            QuestionContent(
                stableID: stableID,
                testVersion: version,
                officialQuestion: officialQuestion,
                acceptedAnswerVariants: acceptedAnswerVariants,
                answerCardinality: .exactly(answerCardinality),
                topic: topic,
                sourceURL: sourceURL,
                sourceRevision: sourceRevision,
                verificationDate: verificationDate,
                isJurisdictionDependent: isJurisdictionDependent,
                isSixtyFiveTwentyQuestion: isSixtyFiveTwentyQuestion
            )
        }
    }
}

enum QuestionBankLoaderError: Error, Equatable {
    case resourceNotFound(name: String)
    case invalidJSON(name: String)
    case unsupportedSchema(name: String, actual: Int)
    case missingQuestions(name: String)
    case missingDerivedSource(version: USCISTestVersion)
    case invalidDerivedSelection(version: USCISTestVersion)
    case validationFailed(version: USCISTestVersion, errors: [QuestionContentValidationError])
}

struct QuestionBankLoader {
    let bundle: Bundle

    init(bundle: Bundle = Bundle(for: QuestionBankBundleMarker.self)) {
        self.bundle = bundle
    }

    func load(version: USCISTestVersion) throws -> [QuestionContent] {
        let resourceName = resourceName(for: version)
        guard let url = bundle.url(forResource: resourceName, withExtension: "json")
                ?? bundle.url(
                    forResource: resourceName,
                    withExtension: "json",
                    subdirectory: "Resources/QuestionBanks"
                ) else {
            throw QuestionBankLoaderError.resourceNotFound(name: resourceName)
        }

        let resource: QuestionBankResource
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            resource = try decoder.decode(QuestionBankResource.self, from: data)
        } catch {
            throw QuestionBankLoaderError.invalidJSON(name: resourceName)
        }

        guard resource.schemaVersion == 1 else {
            throw QuestionBankLoaderError.unsupportedSchema(
                name: resourceName,
                actual: resource.schemaVersion
            )
        }

        let questions: [QuestionContent]
        if let records = resource.questions {
            questions = records.map { $0.question(for: resource.version) }
        } else if let derivedFromVersion = resource.derivedFromVersion,
                  let questionIDs = resource.questionIDs,
                  let sourceQuestions = try? load(version: derivedFromVersion) {
            let sourceByID = Dictionary(uniqueKeysWithValues: sourceQuestions.map { ($0.stableID, $0) })
            guard questionIDs.count == Set(questionIDs).count,
                  questionIDs.allSatisfy({ sourceByID[$0] != nil }) else {
                throw QuestionBankLoaderError.invalidDerivedSelection(version: version)
            }
            questions = questionIDs.compactMap { sourceByID[$0] }.map {
                QuestionContent(
                    stableID: $0.stableID,
                    testVersion: resource.version,
                    officialQuestion: $0.officialQuestion,
                    acceptedAnswerVariants: $0.acceptedAnswerVariants,
                    answerCardinality: $0.answerCardinality,
                    topic: $0.topic,
                    sourceURL: $0.sourceURL,
                    sourceRevision: $0.sourceRevision,
                    verificationDate: $0.verificationDate,
                    isJurisdictionDependent: $0.isJurisdictionDependent,
                    isSixtyFiveTwentyQuestion: true
                )
            }
        } else if resource.derivedFromVersion != nil {
            throw QuestionBankLoaderError.missingDerivedSource(version: version)
        } else {
            throw QuestionBankLoaderError.missingQuestions(name: resourceName)
        }

        guard case .success = QuestionContentValidator.validate(
            questions,
            for: configuration(for: version)
        ) else {
            let failure = QuestionContentValidator.validate(questions, for: configuration(for: version))
            if case .failure(let failure) = failure {
                throw QuestionBankLoaderError.validationFailed(version: version, errors: failure.errors)
            }
            fatalError("Unreachable validation state")
        }
        return questions
    }

    private func resourceName(for version: USCISTestVersion) -> String {
        switch version {
        case .twoThousandEight: "uscis-2008"
        case .twoThousandTwentyFive: "uscis-2025"
        case .sixtyFiveTwenty: "uscis-65-20"
        }
    }

    private func configuration(for version: USCISTestVersion) -> TestConfiguration {
        TestConfiguration.all.first { $0.version == version }!
    }
}