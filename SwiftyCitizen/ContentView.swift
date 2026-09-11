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
        .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self], inMemory: true)
}

private struct WelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Image(systemName: "building.columns.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Welcome to SwiftyCitizen")
                .font(.largeTitle.bold())

            Text("Build confidence with an offline study aid for the USCIS civics test.")
                .font(.title3)

            Text("SwiftyCitizen is for study support only. It does not determine immigration eligibility or replace official USCIS guidance.")
                .foregroundStyle(.secondary)

            Spacer()

            NavigationLink("Set up your test", destination: TestConfigurationView())
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .navigationTitle("Welcome")
    }
}