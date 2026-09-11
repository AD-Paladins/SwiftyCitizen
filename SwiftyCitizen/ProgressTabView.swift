import SwiftUI

struct ProgressTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

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
            .scrollContentBackground(.hidden)
            .background(palette.canvas.ignoresSafeArea())
        }
    }
}

#Preview {
    ProgressTabView()
        .environment(ThemeManager())
}