import SwiftUI

enum AppColor {
    static let ink = Color(red: 0.11, green: 0.14, blue: 0.20)
    static let amber = Color(red: 0.92, green: 0.62, blue: 0.20)
    static let surface = Color(uiColor: .secondarySystemBackground)
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(AppColor.amber)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

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
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ConfigurationSummaryView: View {
    let configuration: OnboardingConfiguration

    var body: some View {
        Group {
            if let testConfiguration = configuration.testConfiguration {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(AppColor.amber)
                        Text(testVersionTitle)
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                    }
                    HStack(spacing: 12) {
                        summaryMetric(value: "\(testConfiguration.questionBankCount)", label: "Questions")
                        summaryMetric(value: "\(testConfiguration.maximumQuestionsAsked)", label: "Asked")
                        summaryMetric(value: "\(testConfiguration.passingScore)", label: "To pass")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
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
                .foregroundStyle(AppColor.ink)
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