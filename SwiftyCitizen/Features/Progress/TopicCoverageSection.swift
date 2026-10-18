import SwiftUI

/// A single topic's coverage snapshot for the carousel. `accuracy` is nil when the topic has no
/// determinate attempts (→ "Not started"); `seen`/`total` are distinct questions attempted / in the
/// bank; `orderIndex` is the topic's stable position across the whole bank, used to give each topic
/// a consistent accent color so users can recognize it at a glance.
struct TopicCoverageRow: Equatable {
    let topic: String
    let accuracy: Double?
    let seen: Int
    let total: Int
    let orderIndex: Int
}

/// Coverage state for a topic, derived from its row. Drives the status pill and progress-bar tint.
enum TopicStatus: Equatable {
    case notStarted
    case needsReview
    case onTrack

    static func forRow(_ row: TopicCoverageRow) -> TopicStatus {
        if row.total == 0 { return .notStarted }
        if row.accuracy == nil && row.seen == 0 { return .notStarted }
        guard let accuracy = row.accuracy else { return .needsReview } // attempted but no determinate signal
        return accuracy < 0.75 ? .needsReview : .onTrack
    }

    /// Whether the topic shows a status pill (everything except comfortably-on-track).
    var isReportable: Bool { self != .onTrack }

    /// Localized label for the status pill, or nil when no pill should render.
    var pillLabel: LocalizedStringKey? {
        switch self {
        case .notStarted: return "progressTopicNotStarted"
        case .needsReview: return "progressAccuracyNeedsReview"
        case .onTrack: return nil
        }
    }
}

/// The "Are you hitting all areas?" section: a header with an "N Areas" count badge, followed by a
/// horizontal, paginated 2×2 grid of topic cards. Matches the Stitch design — each page holds up to
/// `cardsPerPage` topics and pagination dots follow the current page. Tapping a card routes to that
/// topic's review set via `onTopicTap`.
struct TopicCoverageSection: View {
    let rows: [TopicCoverageRow]
    var onTopicTap: (String) -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    private let cardsPerPage = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            header
            carousel
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: Space.sm.value) {
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text("progressTopicCoverageTitle")
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
                Text("progressTopicCoverageSubtitle")
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.dimmed)
            }
            Spacer()
            Text("\(rows.count) \(String(localized: "progressTopicAreasOf"))")
                .font(CivicText.labelSM.font.weight(.semibold))
                .foregroundStyle(palette.onSecondaryContainer)
                .padding(.horizontal, Space.sm.value)
                .padding(.vertical, 3)
                .background(palette.secondaryContainer, in: Capsule())
        }
    }

    // MARK: - Carousel

    @ViewBuilder
    private var carousel: some View {
        let pages = TopicCoverageSection.pages(from: rows, perPage: cardsPerPage)
        if pages.count == 1 {
            TopicPage(cards: pages[0], onTopicTap: onTopicTap)
        } else if !pages.isEmpty {
            CarouselPages(pages: pages, onTopicTap: onTopicTap)
        } else {
            Color.clear.frame(height: 0)
        }
    }

    /// Splits the topic rows into fixed-size pages (2×2 grids). Empty input yields no pages.
    static func pages(from rows: [TopicCoverageRow], perPage: Int) -> [[TopicCoverageRow]] {
        guard perPage > 0 else { return [] }
        return stride(from: 0, to: rows.count, by: perPage).map { start in
            Array(rows[start..<min(start + perPage, rows.count)])
        }
    }
}

/// Paginated carousel. Uses a native paging `TabView` so snapping and the pagination dots are handled
/// by the platform; the page height is measured from content so it never clips under Dynamic Type.
private struct CarouselPages: View {
    let pages: [[TopicCoverageRow]]
    var onTopicTap: (String) -> Void

    @Environment(ThemeManager.self) private var themeManager
    @State private var pageHeight: CGFloat = 300

    var body: some View {
        TabView {
            ForEach(pages.indices, id: \.self) { index in
                TopicPage(cards: pages[index], onTopicTap: onTopicTap)
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { _, height in
                        pageHeight = max(pageHeight, height)
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .tint(themeManager.palette.primaryContainer)
        .frame(height: pageHeight)
    }
}

/// A single carousel page: a 2×2 grid of topic cards.
private struct TopicPage: View {
    let cards: [TopicCoverageRow]
    var onTopicTap: (String) -> Void

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Space.md.value),
                GridItem(.flexible(), spacing: Space.md.value)
            ],
            spacing: Space.md.value
        ) {
            ForEach(cards, id: \.orderIndex) { card in
                TopicCard(row: card, onTopicTap: onTopicTap)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// One topic card: accent badge + status pill, topic name + question count, and a progress bar.
struct TopicCard: View {
    let row: TopicCoverageRow
    var onTopicTap: (String) -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    private var status: TopicStatus { TopicStatus.forRow(row) }

    /// Accent for a topic's badge, cycled by its stable order index so each topic keeps one color.
    private func accentColor(for orderIndex: Int) -> Color {
        switch orderIndex % 3 {
        case 1: return palette.secondary
        case 2: return palette.tertiary
        default: return palette.primary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            HStack(spacing: Space.sm.value) {
                TopicInitialBadge(
                    initial: String(row.topic.first { $0.isLetter } ?? "#"),
                    background: status == .notStarted ? palette.surfaceVariant : accentColor(for: row.orderIndex),
                    foreground: status == .notStarted ? palette.ink : palette.onPrimary
                )
                if let label = status.pillLabel {
                    StatusPill(label: label, background: pillBackground, foreground: pillForeground)
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text(row.topic)
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(row.seen) \(String(localized: "progressTopicQsOf")) \(row.total)")
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.dimmed)
                    .monospacedDigit()
            }
            TopicProgressBar(accuracy: row.accuracy, status: status)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.sm.value)
        .cardStyle()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .circular).stroke(palette.outlineVariant.opacity(0.3)))
        .contentShape(Rectangle())
        .onTapGesture { onTopicTap(row.topic) }
        .accessibilityElement(children: .combine)
        .accessibilityHint("progressTopicReviewHint")
    }

    /// The status pill sits on a soft container (readable in both modes); unseen topics use the
    /// neutral surfaceVariant fill with ink text.
    private var pillBackground: Color {
        status == .notStarted ? palette.surfaceVariant : palette.errorContainer
    }
    private var pillForeground: Color {
        status == .notStarted ? palette.ink : palette.onErrorContainer
    }
}

/// The colored square showing a topic's initial. Public so the accuracy breakdown reuses the exact
/// same badge instead of duplicating it. Unseen topics pass `surfaceVariant` + ink; covered topics
/// pass a flat accent + white (see `TopicCard`).
struct TopicInitialBadge: View {
    let initial: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(initial.uppercased())
            .font(CivicText.labelSM.font.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(width: 28, height: 28)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .circular))
    }
}

/// A small rounded status label (e.g. "Needs review", "Not started").
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

/// The accuracy progress bar: a neutral track with a tinted fill sized to the accuracy, plus the
/// "Accuracy" label and the percentage.
private struct TopicProgressBar: View {
    let accuracy: Double?
    let status: TopicStatus

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    private var fraction: Double {
        guard let accuracy else { return 0 }
        return min(max(accuracy, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            ProgressBarTrack(progress: fraction, tint: fillTint)
            HStack(spacing: Space.sm.value) {
                Text("progressTopicAccuracy")
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.dimmed)
                Spacer(minLength: 0)
                Text(accuracyText(fraction))
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .monospacedDigit()
            }
        }
    }

    private var fillTint: Color {
        switch status {
        case .notStarted: return palette.outlineVariant.opacity(0.4)
        case .needsReview: return palette.danger.opacity(0.8)
        case .onTrack: return palette.primaryContainer
        }
    }

    private func accuracyText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

/// A full-width progress track with a fill sized proportionally to `progress`.
private struct ProgressBarTrack: View {
    let progress: Double
    let tint: Color

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999, style: .circular)
                    .fill(palette.surfaceVariant)
                    .frame(width: proxy.size.width)
                RoundedRectangle(cornerRadius: 999, style: .circular)
                    .fill(tint)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    let rows = [
        TopicCoverageRow(topic: "Colonial & Independence", accuracy: 0.03, seen: 17, total: 17, orderIndex: 0),
        TopicCoverageRow(topic: "1800s Period", accuracy: 0.40, seen: 10, total: 10, orderIndex: 1),
        TopicCoverageRow(topic: "Holidays", accuracy: nil, seen: 0, total: 5, orderIndex: 2),
        TopicCoverageRow(topic: "Rights & Responsibilities", accuracy: nil, seen: 0, total: 10, orderIndex: 3),
        TopicCoverageRow(topic: "System of Government", accuracy: 0.96, seen: 12, total: 12, orderIndex: 4),
        TopicCoverageRow(topic: "Principles of Government", accuracy: 0.88, seen: 8, total: 8, orderIndex: 5)
    ]
    return TopicCoverageSection(rows: rows) { _ in }
        .environment(ThemeManager())
        .padding(Space.md.value)
}
