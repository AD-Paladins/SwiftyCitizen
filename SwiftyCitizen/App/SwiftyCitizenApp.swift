//
//  SwiftyCitizenApp.swift
//  SwiftyCitizen
//
//  Created by andres paladines on 9/10/26.
//

import SwiftUI
import SwiftData

@main
struct SwiftyCitizenApp: App {
    @State private var themeManager = ThemeManager()
    // F1: Home deep-link to the Bookmarked scope. F4: tab-switch guard coordination.
    @State private var pendingNavigation = PendingNavigation()
    @State private var sessionCoordinator = SessionActivityCoordinator()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedOnboardingConfiguration.self,
            StudySession.self,
            QuestionAttempt.self,
            Bookmark.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            #if FILL_USER_DATA
            let context = ModelContext(container)
            try DemoSeeder.seedIfNeeded(in: context)
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
           ContentView()
                  .environment(themeManager)
                  .environment(pendingNavigation)
                  .environment(sessionCoordinator)
                  .environment(\.font, .system(size: 16, weight: .regular, design: .rounded))
                  .tint(themeManager.palette.primary)
        }
        .modelContainer(sharedModelContainer)
    }
}
