import SwiftUI
import SwiftData

struct MainTabView: View {
    let configuration: OnboardingConfiguration
    @Environment(SessionActivityCoordinator.self) private var sessionCoordinator
    @State private var selectedTab: AppTab = .home
    /// Last tab the user actually committed to; used to detect and revert unconfirmed switches.
    @State private var committedTab: AppTab = .home
    @State private var confirmExit = false
    @State private var exitTarget: AppTab = .home

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
        // A native TabView writes the selection directly, so there is no hook to cancel a
        // switch mid-flight. Detect the change here: while a session is active, revert the
        // selection (keeping the session on screen) and confirm before leaving, otherwise the
        // switch would silently discard the running session.
        .onChange(of: selectedTab) { _, newTab in
            guard newTab != committedTab else { return }
            if sessionCoordinator.isActive {
                exitTarget = newTab
                confirmExit = true
                selectedTab = committedTab
            } else {
                committedTab = newTab
            }
        }
        .alert(
            "studySessionSwitchConfirm",
            isPresented: $confirmExit,
            actions: {
                Button(role: .destructive) {
                    // Signal the on-screen session to end + dismiss itself, then navigate.
                    sessionCoordinator.setActive(false)
                    selectedTab = exitTarget
                    committedTab = exitTarget
                } label: {
                    Text("studySessionEndAndSwitch")
                }
            },
            message: {
                Text("studySessionSwitchMessage")
            }
        )
    }
}

#Preview {
    MainTabView(configuration: OnboardingConfiguration(
        filingDate: Date(),
        selectedTestVersion: .twoThousandTwentyFive,
        isSixtyFiveTwentyEligible: false,
        studyLanguage: .english,
        disclaimerAccepted: true,
        shuffleQuestions: false
    ))
    .environment(ThemeManager())
    .environment(SessionActivityCoordinator())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}
