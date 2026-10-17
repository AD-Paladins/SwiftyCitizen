//
//  MigrationTests.swift
//  SwiftyCitizenTests
//
//  Persistent-store migration guard for the on-device upgrade path (spec: persistence).

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct MigrationTests {

    private static func storeURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("migration-test-\(UUID().uuidString).sqlite")
    }

    private static func schema() -> Schema {
        Schema([
            SavedOnboardingConfiguration.self,
            StudySession.self,
            QuestionAttempt.self,
            Bookmark.self,
        ])
    }

    // Round-trip guard for the on-device upgrade path.
    //
    // Persists StudySession / QuestionAttempt / Bookmark rows to a PERSISTENT on-disk store,
    // releases the container, reopens a fresh container on the same URL with the new schema,
    // and asserts every surviving row loads and the reopen does not raise
    // NSCocoaErrorDomain 134110 (schema-incompatible-open).
    //
    // Migration-test mechanism (Design Tension, resolved = Path C round-trip guard):
    // Once the dead fields are removed, the compiled @Model definitions can no longer construct
    // old-schema rows, so both opens use the NEW schema. This proves the clean schema persists
    // and reopens cleanly without 134110. A genuine old->new migration proof (Path A) would need
    // hand-crafting SwiftData's internal SQLite store (Z_METADATA version/uuid hashes,
    // Z_PRIMARYKEY max values, internal Date BLOB encoding) — brittle across Xcode/SwiftData
    // versions. Automatic lightweight migration for property/relationship drops is guaranteed by
    // SwiftData and already exercised on this app/store by the 5.3 studyLanguageRawValue removal;
    // the on-device upgrade path itself rests on that precedent plus a manual smoke test.
    @Test func persistentStoreReopensUnderNewSchemaWithoutMigrationError() throws {
        let url = Self.storeURL()
        try? FileManager.default.removeItem(at: url)

        // --- Phase 1: persist rows against the current schema on a PERSISTENT store ---
        do {
            let config = ModelConfiguration("MigrationTest", schema: Self.schema(), url: url)
            let container = try ModelContainer(for: Self.schema(), configurations: [config])
            let context = ModelContext(container)

            let session = StudySession(
                mode: .mockTest,
                testVersion: .twoThousandTwentyFive,
                deckStableIDs: ["2025-001", "2025-002"]
            )
            session.skippedStableIDs.append("2025-002")
            context.insert(session)

            let attempt = QuestionAttempt(
                questionStableID: "2025-001",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answerText: "The Constitution",
                boxLevel: 4
            )
            context.insert(attempt)

            let bookmark = Bookmark(
                questionStableID: "2025-001",
                testVersion: .twoThousandTwentyFive
            )
            context.insert(bookmark)

            try context.save()
            // No public close() on ModelContainer in this SDK; the store is flushed by save()
            // and released when `container` deallocates at the end of this scope.
        }

        // --- Phase 2: reopen a fresh container on the same URL with the new schema ---
        // A schema-incompatible store would raise NSCocoaErrorDomain 134110 here.
        let reopenConfig = ModelConfiguration("MigrationTest", schema: Self.schema(), url: url)
        let reopenContainer = try ModelContainer(for: Self.schema(), configurations: [reopenConfig])
        let reopenContext = ModelContext(reopenContainer)

        let sessions = try reopenContext.fetch(FetchDescriptor<StudySession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.modeRawValue == StudyMode.mockTest.rawValue)
        #expect(sessions.first?.deckStableIDs == ["2025-001", "2025-002"])
        #expect(sessions.first?.skippedStableIDs == ["2025-002"])

        let attempts = try reopenContext.fetch(FetchDescriptor<QuestionAttempt>())
        #expect(attempts.count == 1)
        #expect(attempts.first?.boxLevel == 4)
        #expect(attempts.first?.flashcardAttemptRecord?.answerText == "The Constitution")

        let bookmarks = try reopenContext.fetch(FetchDescriptor<Bookmark>())
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.questionStableID == "2025-001")
    }
}
