import SwiftUI
import SwiftData

struct MainTabView: View {
    let configuration: OnboardingConfiguration
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeDashboardView(configuration: configuration, selectedTab: $selectedTab)
            }
            Tab(AppTab.study.title, systemImage: AppTab.study.systemImage, value: AppTab.study) {
                StudyView(configuration: configuration)
            }
            Tab(AppTab.practice.title, systemImage: AppTab.practice.systemImage, value: AppTab.practice) {
                PracticeView(configuration: configuration)
            }
            Tab(AppTab.progress.title, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                ProgressTabView()
            }
        }
    }
}

#Preview {
    MainTabView(configuration: OnboardingConfiguration(
        filingDate: Date(),
        selectedTestVersion: .twoThousandTwentyFive,
        isSixtyFiveTwentyEligible: false,
        studyLanguage: .english,
        disclaimerAccepted: true
    ))
    .environment(ThemeManager())
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}