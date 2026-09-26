//
//  ContentView.swift
//  SwiftyCitizen
//
//  Created by andres paladines on 9/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedConfigurations: [SavedOnboardingConfiguration]

    var body: some View {
        if let configuration = savedConfigurations.first?.configuration {
            MainTabView(configuration: configuration)
        } else {
            NavigationStack {
                WelcomeView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager())
        .modelContainer(for: [SavedOnboardingConfiguration.self], inMemory: true)
}

private struct WelcomeView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 0)

                Image(systemName: "building.columns.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text("welcomeTitle")
                    .font(.largeTitle.bold())

                 Text("welcomeSubtitle")
                    .font(.title3)

                 Text("welcomeDisclaimer")
                    .foregroundStyle(palette.dimmed)

                Spacer(minLength: 0)

                NavigationLink("welcomeSetUpButton", destination: TestConfigurationView())
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: verticalSizeClass == .compact ? 400 : 600)
            .padding(24)
        }
        .defaultScrollAnchor(.center)
        .navigationTitle("welcomeNavTitle")
        .background(palette.canvas.ignoresSafeArea())
    }
}
