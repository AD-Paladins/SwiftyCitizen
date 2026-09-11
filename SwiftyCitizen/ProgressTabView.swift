import SwiftUI

struct ProgressTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "No progress yet",
                        message: "Your attempts, accuracy, and coverage will appear here after your first study session."
                    )
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressTabView()
}