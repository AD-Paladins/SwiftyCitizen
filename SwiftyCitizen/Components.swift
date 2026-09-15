import SwiftUI

struct SessionFeedbackIndicator: View {
    let answer: MockTestAnswer

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        let feedback = AnswerFeedback.make(answer, palette: palette)
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: feedback.image)
                .font(.headline)
                .foregroundStyle(feedback.tint)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Official answer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(question.acceptedAnswerVariants, id: \.self) { variant in
                HStack(alignment: .top, spacing: 8) {
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
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
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
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(palette.primary)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ConfigurationSummaryView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        Group {
            if let testConfiguration = configuration.testConfiguration {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(palette.primary)
                        Text(testVersionTitle)
                            .font(.headline)
                            .foregroundStyle(palette.ink)
                    }
                    HStack(spacing: 12) {
                        summaryMetric(value: "\(testConfiguration.questionBankCount)", label: "Questions")
                        summaryMetric(value: "\(testConfiguration.maximumQuestionsAsked)", label: "Asked")
                        summaryMetric(value: "\(testConfiguration.passingScore)", label: "To pass")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var testVersionTitle: String {
        configuration.selectedTestVersion?.displayName ?? "Test configuration"
    }

    private func summaryMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(palette.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            HStack(spacing: 8) {
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
            .padding(16)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .border(isSelected ? palette.primary : palette.ink.opacity(0.3), width: isSelected ? 2 : 1)
        .accessibilityLabel(isSelected ? "\(text), selected" : text)
    }
}