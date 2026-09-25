import SwiftUI

struct SessionFeedbackIndicator: View {
    let answer: MockTestAnswer

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        let feedback = AnswerFeedback.make(answer, palette: palette)
        HStack(alignment: .center, spacing: Space.sm.value) {
            Image(systemName: feedback.image)
                .font(.headline)
                .foregroundStyle(feedback.tint)
                .accessibilityHidden(true)
            Text(feedback.label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(feedback.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AcceptedAnswerCard: View {
    let question: QuestionContent

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("Official answer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.dimmed)

            ForEach(question.acceptedAnswerVariants, id: \.self) { variant in
                HStack(alignment: .top, spacing: Space.sm.value) {
                    Image(systemName: "checkmark")
                        .font(.footnote.bold())
                        .foregroundStyle(palette.success)
                        .accessibilityHidden(true)
                    Text(variant)
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardStyle()
    }
}

struct AnswerFeedback {
    let image: String
    let label: String
    let tint: Color

    static func make(_ answer: MockTestAnswer, palette: AppPalette) -> AnswerFeedback {
        if !answer.isCorrect {
            return AnswerFeedback(image: "xmark.circle.fill", label: "Incorrect", tint: palette.danger)
        }
        switch answer.matchType {
        case .complete:
            return AnswerFeedback(image: "checkmark.seal.fill", label: "Correct", tint: palette.success)
        case .partial:
            return AnswerFeedback(
                image: "exclamationmark.triangle.fill",
                label: "Accepted: your answer covers one accepted version of the official answer.",
                tint: palette.warning
            )
        case .none:
            return AnswerFeedback(image: "xmark.circle.fill", label: "Incorrect", tint: palette.danger)
        }
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .pillButton(background: palette.primary)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(spacing: Space.sm.value) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(palette.dimmed)
            Text(title)
                .font(CivicText.headlineSM.font)
            Text(message)
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.dimmed)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.lg.value)
        .padding(.horizontal, 12)
        .cardStyle()
    }
}

struct ConfigurationSummaryView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        Group {
            if let testConfiguration = configuration.testConfiguration {
                VStack(alignment: .leading, spacing: Space.sm.value) {
                     HStack {
                         Image(systemName: "checkmark.shield")
                             .foregroundStyle(palette.primary)
                         Text(testVersionTitle)
                             .font(CivicText.headlineSM.font)
                             .foregroundStyle(palette.ink)
                     }
                     HStack(spacing: Space.md.value) {
                        SummaryMetricView(value: "\(testConfiguration.questionBankCount)", label: "Questions")
                        SummaryMetricView(value: "\(testConfiguration.maximumQuestionsAsked)", label: "Asked")
                        SummaryMetricView(value: "\(testConfiguration.passingScore)", label: "To pass")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()
            }
        }
    }

    private var testVersionTitle: String {
        configuration.selectedTestVersion?.displayName ?? "Test configuration"
    }

 }

struct SummaryMetricView: View {
    let value: String
    let label: String
    var tint: Color? = nil

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
         VStack(alignment: .leading, spacing: Space.xs.value) {
             Text(label)
                 .font(CivicText.labelMD.font)
                 .foregroundStyle(palette.dimmed)
             Text(value)
                 .font(CivicText.headlineLG.font)
                 .foregroundStyle(tint ?? palette.ink)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         .padding(.horizontal, Space.md.value)
         .padding(.vertical, Space.sm.value)
         .cardStyle()
     }
}

struct StudyEntryCard<Route: Hashable>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionLabel: String
    let iconBackground: Color
    let iconForeground: Color
    let actionTint: Color
    let value: Route

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        NavigationLink(value: value) {
            HStack(spacing: Space.lg.value) {
                ZStack {
                    Circle().fill(iconBackground)
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(iconForeground)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: Space.xs.value) {
                    Text(title)
                        .font(CivicText.headlineSM.font)
                        .foregroundStyle(palette.ink)
                    Text(subtitle)
                        .font(CivicText.bodySM.font)
                        .foregroundStyle(palette.dimmed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Space.xs.value) {
                    Text(actionLabel)
                        .font(CivicText.labelSM.font)
                        .fontWeight(.bold)
                        .foregroundStyle(actionTint)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.dimmed)
                }
            }
            .padding(Space.lg.value)
        }
        .cardStyle()
        .accessibilityLabel(Text("\(title), \(actionLabel)"))
    }
}

struct StudyEntryPointView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ScrollView {
            EmptyStateView(systemImage: systemImage, title: title, message: message)
                .padding(24)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SelectionTile: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.sm.value) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundStyle(palette.primary)
                }
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.md)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .border(isSelected ? palette.primary : palette.ink.opacity(0.3), width: isSelected ? 2 : 1)
        .accessibilityLabel(isSelected ? "\(text), selected" : text)
    }
}