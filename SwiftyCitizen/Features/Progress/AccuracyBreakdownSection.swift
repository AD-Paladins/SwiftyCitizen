import SwiftUI

/// The "Accuracy Breakdown" section: a single card with an overall-accuracy header (plus a trend
/// pill) and one row per attempted topic — a colored dot, the topic name, its accuracy, and a
/// status pill. It is the simpler, list-based sibling of the topic carousel: the same per-topic
/// accuracy, easier to scan at a glance. Rows are tappable and route to the topic's review set.
struct AccuracyBreakdownSection: View {
    /// Attempted topics only (accuracy != nil), in first-appearance order. Topics with no
    /// determinate accuracy are already excluded by the caller.
    let rows: [TopicCoverageRow]
    let overallAccuracy: Double?
    let trend: ProgressAnalytics.AccuracyTrend
    var onTopicTap: (String) -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            header
            card
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            Text("progressAccuracyBreakdownTitle")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
            Text("progressAccuracyBreakdownSubtitle")
                .font(CivicText.bodySM.font)
                .foregroundStyle(palette.dimmed)
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider().background(palette.surfaceVariant)
            if rows.isEmpty {
                Text("progressAccuracyBreakdownEmpty")
                    .font(CivicText.bodyMD.font)
                    .foregroundStyle(palette.dimmed)
                    .padding(.top, Space.md.value)
            } else {
                VStack(alignment: .leading, spacing: Space.sm.value) {
                    ForEach(rows, id: \.topic) { row in
                        accuracyRow(row)
                    }
                }
                .padding(.top, Space.sm.value)
            }
        }
        .padding(Space.md.value)
        .cardStyle()
    }

    /// The overall-accuracy headline on the left and the trend pill on the right. Hidden trend when
    /// there is not enough history to form a delta (`.unknown`) — nothing is shown rather than a
    /// misleading direction.
    private var headerRow: some View {
        HStack(alignment: .center, spacing: Space.md.value) {
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text("progressAccuracyOverall")
                    .font(CivicText.labelSM.font.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundStyle(palette.dimmed)
                Text(accuracyText(overallAccuracy))
                    .font(CivicText.displayLG.font)
                    .foregroundStyle(palette.primary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
            if let pill = trendPill { pill }
        }
    }

    private func accuracyRow(_ row: TopicCoverageRow) -> some View {
        let status = TopicStatus.forRow(row)
        return HStack(spacing: Space.sm.value) {
            Circle()
                .fill(TopicCoverageSection.accentColor(for: row.orderIndex, palette: palette))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 0) {
                Text(row.topic)
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text(accuracyText(row.accuracy))
                .font(CivicText.labelMD.font.weight(.semibold))
                .foregroundStyle(palette.ink)
                .monospacedDigit()
            if let pill = pill(for: status) {
                StatusPill(label: pill.label, background: pill.background, foreground: pill.foreground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.sm.value)
        .background(palette.canvas.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .circular))
        .contentShape(Rectangle())
        .onTapGesture { onTopicTap(row.topic) }
    }

    // MARK: - Trend pill

    private var trendPill: AnyView? {
        switch trend {
        case .rising:
            return AnyView(trendPillView(systemImage: "trending.up", label: "progressAccuracyTrendRising", background: palette.primaryContainer, foreground: palette.onPrimaryContainer))
        case .flat:
            return AnyView(trendPillView(systemImage: "minus", label: "progressAccuracyTrendFlat", background: palette.surfaceVariant, foreground: palette.ink))
        case .falling:
            return AnyView(trendPillView(systemImage: "trending.down", label: "progressAccuracyTrendFalling", background: palette.errorContainer, foreground: palette.onErrorContainer))
        case .unknown:
            return nil
        }
    }

    private func trendPillView(systemImage: String, label: LocalizedStringKey, background: Color, foreground: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(CivicText.labelSM.font)
                .frame(width: 11, height: 11)
            Text(label)
                .font(CivicText.labelSM.font.weight(.semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(background, in: Capsule())
    }

    // MARK: - Status pill styling

    /// The breakdown shows "Needs review" for low-accuracy topics and "High confidence" for on-track
    /// ones (the carousel's third state, "Not started", never appears here — rows are attempted only).
    /// Unlike `TopicStatus.pillLabel` (which hides the pill for on-track), this always returns a
    /// label so every row reads its health at a glance.
    private func pill(for status: TopicStatus) -> (label: LocalizedStringKey, background: Color, foreground: Color)? {
        switch status {
        case .notStarted: return ("progressTopicNotStarted", palette.surfaceVariant, palette.ink)
        case .needsReview: return ("progressAccuracyNeedsReview", palette.errorContainer, palette.onErrorContainer)
        case .onTrack: return ("progressAccuracyHighConfidence", palette.primaryContainer, palette.onPrimaryContainer)
        }
    }

    private func accuracyText(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
    }
}

/// A small rounded status label (e.g. "Needs review", "High confidence"). Kept local to this section
/// because its status→color mapping differs from the carousel's.
private struct StatusPill: View {
    let label: LocalizedStringKey
    let background: Color
    let foreground: Color

    var body: some View {
        Text(label)
            .font(CivicText.labelSM.font.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .circular))
    }
}

#Preview {
    let rows = [
        TopicCoverageRow(topic: "Colonial & Independence", accuracy: 0.03, seen: 17, total: 17, orderIndex: 0),
        TopicCoverageRow(topic: "System of Government", accuracy: 0.40, seen: 10, total: 10, orderIndex: 4),
        TopicCoverageRow(topic: "Principles of Government", accuracy: 0.92, seen: 8, total: 8, orderIndex: 5)
    ]
    return AccuracyBreakdownSection(
        rows: rows,
        overallAccuracy: 0.47,
        trend: .rising,
        onTopicTap: { _ in }
    )
    .environment(ThemeManager())
    .padding(Space.md.value)
}
