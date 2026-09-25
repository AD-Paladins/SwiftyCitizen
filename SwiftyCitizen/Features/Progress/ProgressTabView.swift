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
                         title: "progress.noProgressTitle",
                         message: "progress.noProgressMessage"
                     )
                     .listRowSeparator(.hidden)
                 }
             }
             .navigationTitle("progress.title")
            .scrollContentBackground(.hidden)
            .background(palette.canvas.ignoresSafeArea())
        }
    }
}

#Preview {
    ProgressTabView()
        .environment(ThemeManager())
}