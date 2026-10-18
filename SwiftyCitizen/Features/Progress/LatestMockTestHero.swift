import SwiftUI

/// The dark-emerald "Latest mock test" card from the Stitch design.
///
/// Self-contained and reusable: it only receives the derived data and fires callbacks for its two
/// actions (Retake / Mistakes). It does not own navigation — the consumer wires those to wherever
/// they belong (see `ProgressTabView`). Typography maps to the locked `CivicText` (SF Pro Rounded);
/// the gradient / shadow / shapes are reproduced faithfully from the design hex.
struct LatestMockTestHero: View {
    /// The most recent completed mock test result, or nil for the empty state.
    let result: MockTestResult?

    /// Precomputed coverage string, e.g. "3 of 5 seen".
    let coverage: String

    /// Formatted end date of the last mock test, or nil.
    let date: String?

    /// Retake → returns to the practice flow.
    let onRetake: () -> Void

    /// Mistakes → opens the mistakes screen.
    let onMistakes: () -> Void

    @Environment(ThemeManager.self) private var themeManager

    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let result {
                heroCard(result)
            } else {
                emptyCard
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card states

    private func heroCard(_ result: MockTestResult) -> some View {
        let of = String(localized: "commonOf")
        let scoreFraction = Double(result.correct) / Double(result.asked)
        let passingPct = Int((Double(result.passingScore) / Double(result.asked) * 100).rounded())
        let barTint = result.passed ? palette.success : palette.warning

        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Space.lg.value) {
                HStack(alignment: .top, spacing: Space.sm.value) {
                    VStack(alignment: .leading, spacing: Space.xs.value) {
                        Text("progressHeroMockLabel")
                            .font(CivicText.labelMD.font.weight(.medium))
                            .tracking(0.5)
                            .foregroundStyle(palette.onPrimary.opacity(0.9))
                        Text("\(result.correct) \(of) \(result.asked)")
                            .font(CivicText.displayLG.font)
                            .tracking(-0.5)
                            .foregroundStyle(palette.onPrimary)
                    }
                    Spacer()
                    statusPill(passed: result.passed, tint: barTint)
                }

                VStack(alignment: .leading, spacing: Space.sm.value) {
                    progressBar(fraction: scoreFraction, tint: barTint)
                    VStack(alignment: .leading, spacing: Space.sm.value) {
                        Text(String(localized: "progressPassingMarkPrefix") + " \(result.passingScore) \(of) \(result.asked) (\(passingPct)%)")
                        Text(dateCoverage)
                    }
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.onPrimary.opacity(0.75))
                }

                HStack(spacing: Space.md.value) {
                    retakeButton
                    mistakesButton
                }
                .frame(width: .infinity, height: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .background(heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: Space.xl.value))
        .shadow(color: Color(red: 11 / 255.0, green: 77 / 255.0, blue: 60 / 255.0).opacity(0.28), radius: 24, y: 8)
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("progressHeroMockLabel")
                .font(CivicText.labelMD.font.weight(.medium))
                .tracking(0.5)
                .foregroundStyle(palette.onPrimary.opacity(0.9))
            Text("progressHeroNoMock")
                .font(CivicText.labelMD.font.weight(.semibold))
                .foregroundStyle(palette.onPrimary.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .background(heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: Space.xl.value))
    }

    // MARK: - Subviews

    private func statusPill(passed: Bool, tint: Color) -> some View {
        HStack(spacing: Space.xs.value) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(passed ? "progressMockPassed" : "progressMockNotPassed")
                .font(CivicText.labelMD.font.weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.20)))
        .overlay(Capsule().stroke(tint.opacity(0.30), lineWidth: 1))
    }

    private func progressBar(fraction: Double, tint: Color) -> some View {
        let clamped = max(0, min(1, fraction))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.25))
                Capsule().fill(tint).frame(width: geo.size.width * clamped)
            }
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }

    /// The dark-emerald card background from the Stitch design (design hex).
    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 11 / 255.0, green: 77 / 255.0, blue: 60 / 255.0),
                Color(red: 9 / 255.0, green: 66 / 255.0, blue: 51 / 255.0),
                Color(red: 4 / 255.0, green: 40 / 255.0, blue: 30 / 255.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var retakeButton: some View {
        Button {
            onRetake()
        } label: {
            HStack(spacing: Space.sm.value) {
                Image(systemName: "repeat")
                Text("progressRetakeMockExam")
            }
            .font(CivicText.labelMD.font.weight(.semibold))
            .foregroundStyle(palette.onPrimary)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Capsule().fill(palette.onPrimary.opacity(0.10)))
        .overlay(Capsule().stroke(palette.onPrimary.opacity(0.15), lineWidth: 1))
    }

    private var mistakesButton: some View {
        Button {
            onMistakes()
        } label: {
            HStack(spacing: Space.sm.value) {
                Image(systemName: "book.fill")
                Text("progressHeroMistakes")
            }
            .font(CivicText.labelMD.font.weight(.semibold))
            .foregroundStyle(palette.onPrimary.opacity(0.9))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Capsule().fill(palette.onPrimary.opacity(0.06)))
        .overlay(Capsule().stroke(palette.onPrimary.opacity(0.30), lineWidth: 1))
    }
    
    // MARK: - Computed vars
    var dateCoverage: String {
        guard let safeDate = date else {
            return "No Date confirmed • \(coverage)"
        }
        return "\(safeDate) • \(coverage)"
    }
}

#Preview("Passed") {
    NavigationStack {
        LatestMockTestHero(
            result: MockTestResult(asked: 20, correct: 15, passingScore: 12),
            coverage: "3 of 5 seen",
            date: "Sep 30, 2026",
            onRetake: {},
            onMistakes: {}
        )
        .padding()
    }
    .environment(ThemeManager())
}

#Preview("Failed") {
    NavigationStack {
        LatestMockTestHero(
            result: MockTestResult(asked: 20, correct: 8, passingScore: 12),
            coverage: "3 of 5 seen",
            date: "Sep 30, 2026",
            onRetake: {},
            onMistakes: {}
        )
        .padding()
    }
    .environment(ThemeManager())
}

#Preview("Empty") {
    NavigationStack {
        LatestMockTestHero(
            result: nil,
            coverage: "3 of 5 seen",
            date: nil,
            onRetake: {},
            onMistakes: {}
        )
        .padding()
    }
    .environment(ThemeManager())
}
