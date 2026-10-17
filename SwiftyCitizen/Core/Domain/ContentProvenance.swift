import Foundation

/// Provenance of a question bank — where its content officially comes from and when it was last
/// verified. Read from the shared `sourceURL` / `sourceRevision` / `verificationDate` fields every
/// `QuestionContent` carries; all three come from one bundled JSON per version, so they are
/// consistent across that version's bank (see `extract(from:)`).
struct ContentProvenance: Equatable {
    /// The official source URL. `nil` when the bank could not be loaded or a question lacks it.
    let sourceURL: URL?
    /// The official revision label (e.g. "M-1778 (09/25)"). `nil` when absent.
    let sourceRevision: String?
    /// When the source content was last verified against USCIS. `nil` when absent.
    let verificationDate: Date?
    /// Distinct (sourceURL, sourceRevision, verificationDate) references across the bank. `1` means
    /// every question traces to one official reference; `>1` means the bank mixes references and
    /// callers must surface that honestly rather than picking one arbitrarily. `0` when empty.
    let referenceCount: Int
}

extension ContentProvenance {
    /// One official reference: the (sourceURL, sourceRevision, verificationDate) triple that every
    /// question in a single bundled bank shares.
    private struct ReferenceKey: Hashable {
        let url: String?
        let revision: String
        let date: Date?
    }

    /// Extract shared provenance from a loaded bank. Reads the metadata every question carries and
    /// reports the true number of distinct references so a mixed bank is shown honestly instead of
    /// silently picking the first question's values. Whitespace is ignored when grouping revisions,
    /// matching the loader's validation.
    static func extract(from questions: [QuestionContent]) -> ContentProvenance {
        // Tuples don't conform to Hashable, so a small key struct carries the three fields that
        // together identify one official reference.
        let references = Set(
            questions.map { ReferenceKey(
                url: $0.sourceURL?.absoluteString,
                revision: $0.sourceRevision.trimmingCharacters(in: .whitespacesAndNewlines),
                date: $0.verificationDate
            ) }
        )
        return ContentProvenance(
            sourceURL: questions.first?.sourceURL,
            sourceRevision: questions.first?.sourceRevision,
            verificationDate: questions.first?.verificationDate,
            referenceCount: references.count
        )
    }
}
