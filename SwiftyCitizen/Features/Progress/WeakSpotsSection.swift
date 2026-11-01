import SwiftUI

/// The "Critical weak spots" section: a header with an "N Weak Items" count, then either an empty
/// state or a card listing the lowest-accuracy cards (topic + question text + accuracy), each
/// tappable to route to its topic. A full-width button queues a targeted review of the set.
///
/// Decoupled and reusable: all data arrives as parameters rather than reaching into a parent view.
/// `questionText` maps a `stableID` to its official question text (so this never imports the bank),
/// `onTopicTap` routes a topic tap, and `onQueue` performs the review-queue action — navigation
/// state stays with the consumer that owns it.
struct WeakSpotsSection: View {
    let weakSpots: [ProgressAnalytics.WeakSpot]

    /// stableID -> official question text, so rows show the question instead of the raw ID.
    let questionText: (String) -> String

    /// Route a topic tap (e.g. open that topic's review set).
    var onTopicTap: (String) -> Void

    /// Queue a targeted review of this weak-spot set. Navigation state stays with the caller.
    var onQueue: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            header
            if weakSpots.isEmpty {
                Text("progressWeakSpotsNone")
                    .font(CivicText.bodyMD.font)
                    .foregroundStyle(palette.dimmed)
            } else {
                VStack(spacing: 0) {
                    ForEach(weakSpots, id: \.stableID) { spot in
                        weakSpotRow(spot)
                    }
                }
                .cardStyle()
            }
            if !weakSpots.isEmpty {
                queueButton(count: weakSpots.count)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            Text("progressWeakSpotsHeader")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
            Text("\(weakSpots.count) \(String(localized: "progressWeakItems"))")
                .font(CivicText.labelMD.font)
                .foregroundStyle(palette.dimmed)
                .monospacedDigit()
        }
    }

    // MARK: - Rows

    private func weakSpotRow(_ spot: ProgressAnalytics.WeakSpot) -> some View {
        let question = questionText(spot.stableID)
        return HStack(spacing: Space.sm.value) {
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text(question)
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(spot.topic)
                    .font(CivicText.labelSM.font)
                    .foregroundStyle(palette.dimmed)
            }
            Spacer()
            Text(accuracyText(spot.accuracy))
                .font(CivicText.labelMD.font.weight(.semibold))
                .foregroundStyle(palette.ink)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.sm.value)
        .background(palette.canvas.opacity(0.4))
        .contentShape(Rectangle())
        .onTapGesture { onTopicTap(spot.topic) }
    }

    // MARK: - Queue button

    private func queueButton(count: Int) -> some View {
        Button(action: onQueue) {
            Text("\(count) \(String(localized: "progressQueueWeakItems"))")
                .font(CivicText.labelMD.font.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(ControlSize.regular)
        .tint(palette.primary)
        .foregroundStyle(palette.primary)
    }

    // MARK: - Helpers

    private func accuracyText(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
    }
}

#Preview("With spots") {
    let spots = [
        ProgressAnalytics.WeakSpot(stableID: "Q-1801-0042", topic: "Constitution", accuracy: 0.12, lastAssessment: nil),
        ProgressAnalytics.WeakSpot(stableID: "Q-1801-0117", topic: "Rights & Responsibilities", accuracy: 0.20, lastAssessment: nil),
        ProgressAnalytics.WeakSpot(stableID: "Q-1801-0203", topic: "Historical Documents", accuracy: nil, lastAssessment: nil)
    ]
    let questions: [String: String] = [
        "Q-1801-0042": "What are the two parts of the U.S. Congress?",
        "Q-1801-0117": "What is the highest voice of the people?",
        "Q-1801-0203": "Who wrote the Declaration of Independence?"
    ]
    return WeakSpotsSection(
        weakSpots: spots,
        questionText: { questions[$0] ?? $0 },
        onTopicTap: { _ in },
        onQueue: {}
    )
    .environment(ThemeManager())
    .padding(Space.md.value)
}

#Preview("Empty") {
    WeakSpotsSection(
        weakSpots: [],
        questionText: { $0 },
        onTopicTap: { _ in },
        onQueue: {}
    )
    .environment(ThemeManager())
    .padding(Space.md.value)
}
