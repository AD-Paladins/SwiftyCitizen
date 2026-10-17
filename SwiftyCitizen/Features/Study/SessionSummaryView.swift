import SwiftUI

struct SessionSummaryView: View {
    let answeredCount: Int
    let assessments: [SelfAssessment]
    /// Weak topics computed from this session's attempts (empty when nothing was weak).
    let weakTopics: [WeakTopic]
    /// Weak-card stable IDs for the recommended review queue; only used when `weakTopics` is non-empty.
    let configuration: OnboardingConfiguration
    let weakStableIDs: Set<String>
    let onFinish: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(palette.success)
                    .accessibilityHidden(true)

                Text("studySummaryComplete")
                     .font(.largeTitle.bold())
                     .foregroundStyle(palette.ink)
                     .padding(.top, 16)

                 let unit = answeredCount == 1 ? String(localized: "studySummaryReviewedSingular") : String(localized: "studySummaryReviewedPlural")
                 Text("\(String(localized: "studySummaryReviewedPrefix"))\(answeredCount) \(unit)")
                     .font(.subheadline)
                     .foregroundStyle(palette.dimmed)
                     .padding(.top, 4)

                 VStack(spacing: 8) {
                     ForEach(SelfAssessment.allCases, id: \.self) { assessment in
                         summaryRow(assessment: assessment)
                     }
                 }
                 .padding(20)
                 .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                 .padding(.top, 24)

                 if !weakTopics.isEmpty {
                     weakTopicsSection
                 }

                 PrimaryActionButton(title: "studySummaryDone", systemImage: "checkmark") {
                     onFinish()
                 }
                 .padding(.top, 28)
                 .padding(.bottom, 24)
             }
             .frame(maxWidth: .infinity, minHeight: geometryHeight)
             .padding(24)
         }
         .defaultScrollAnchor(.center)
         .background(palette.canvas.ignoresSafeArea())
     }

     /// Honest "what you're weak in" + one next action. Shown only when the session produced weak
     /// topics, so no busywork is invented for a clean session. The action reuses the existing
     /// `.lowAccuracy` review queue (TargetedReviewView opens straight at `weakStableIDs`).
     private var weakTopicsSection: some View {
         VStack(alignment: .leading, spacing: 12) {
             Text("studySummaryWeakTopicsTitle")
                 .font(.headline)
                 .foregroundStyle(palette.ink)

             ForEach(weakTopics) { topic in
                 weakTopicRow(topic)
             }

             NavigationLink(destination: TargetedReviewView(configuration: configuration, weakCards: weakStableIDs)) {
                 Label("studySummaryReviewAction", systemImage: "arrow.right")
                     .font(.headline)
                     .frame(maxWidth: .infinity)
             }
             .buttonStyle(.borderedProminent)
             .controlSize(.large)
             .tint(palette.primary)
             .padding(.top, 4)
         }
         .padding(20)
         .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
         .padding(.top, 24)
     }

     private func weakTopicRow(_ topic: WeakTopic) -> some View {
         HStack(spacing: 8) {
             Image(systemName: "exclamationmark.triangle")
                 .font(.footnote)
                 .foregroundStyle(palette.warning)
                 .accessibilityHidden(true)
             Text(topic.topic)
                 .font(.subheadline)
                 .foregroundStyle(palette.ink)
             Spacer()
             Text("\(topic.weakCards)")
                 .font(.subheadline.monospacedDigit())
                 .foregroundStyle(palette.dimmed)
         }
         .accessibilityElement(children: .combine)
         .accessibilityLabel("\(topic.topic) \(topic.weakCards) \(String(localized: "studySummaryWeakCardsLabel"))")
     }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var geometryHeight: CGFloat {
        verticalSizeClass == .compact ? 400 : 600
    }

    private func summaryRow(assessment: SelfAssessment) -> some View {
        let count = assessments.filter { $0 == assessment }.count
        return HStack {
            Label(assessment.displayName, systemImage: assessment.systemImage)
                .font(.subheadline)
                .foregroundStyle(palette.ink)
            Spacer()
            Text("\(count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(palette.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(assessment.displayName) \(count)")
    }
}

#Preview {
    SessionSummaryView(
        answeredCount: 10,
        assessments: [.again, .again, .hard, .gotIt, .gotIt, .gotIt, .gotIt, .gotIt, .gotIt, .gotIt],
        weakTopics: [WeakTopic(topic: "Government", weakCards: 2)],
        configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ),
        weakStableIDs: ["2025-001"],
        onFinish: {}
    )
    .environment(ThemeManager())
}
