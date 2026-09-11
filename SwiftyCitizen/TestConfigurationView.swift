import SwiftUI
import SwiftData

struct TestConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @Environment(\.dismiss) private var dismiss
    @Query private var savedConfigurations: [SavedOnboardingConfiguration]

    @State private var filingDate: Date
    @State private var isSixtyFiveTwentyEligible: Bool
    @State private var studyLanguage: StudyLanguage?
    @State private var disclaimerAccepted: Bool

    init(configuration: OnboardingConfiguration? = nil) {
        _filingDate = State(initialValue: configuration?.filingDate ?? Date())
        _isSixtyFiveTwentyEligible = State(initialValue: configuration?.isSixtyFiveTwentyEligible ?? false)
        _studyLanguage = State(initialValue: configuration?.studyLanguage)
        _disclaimerAccepted = State(initialValue: configuration?.disclaimerAccepted ?? false)
    }

    private var configuration: OnboardingConfiguration {
        OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: derivedVersion,
            isSixtyFiveTwentyEligible: isSixtyFiveTwentyEligible,
            studyLanguage: studyLanguage,
            disclaimerAccepted: disclaimerAccepted
        )
    }

    private var derivedVersion: USCISTestVersion {
        isSixtyFiveTwentyEligible
            ? .sixtyFiveTwenty
            : (filingDate < OnboardingConfiguration.testVersionChangeDate ? .twoThousandEight : .twoThousandTwentyFive)
    }

    var body: some View {
        Form {
            Section("Filing date") {
                DatePicker("N-400 filing date", selection: $filingDate, in: ...Date(), displayedComponents: .date)
                Text("This selects the applicable civics test rules unless you choose the 65/20 option.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Test version") {
                Toggle("I qualify for the 65/20 special consideration", isOn: $isSixtyFiveTwentyEligible)
                LabeledContent("Selected version", value: versionTitle)
            }

            Section("Study language") {
                Picker("Study support", selection: $studyLanguage) {
                    Text("Choose a language").tag(nil as StudyLanguage?)
                    ForEach(StudyLanguage.allCases) { language in
                        Text(language.displayName).tag(language as StudyLanguage?)
                    }
                }
            }

            if let testConfiguration = configuration.testConfiguration {
                Section("Your study set") {
                    LabeledContent("Question bank", value: "\(testConfiguration.questionBankCount) questions")
                    LabeledContent("Questions asked", value: "Up to \(testConfiguration.maximumQuestionsAsked)")
                    LabeledContent("Passing score", value: "\(testConfiguration.passingScore) correct")
                }
            }

            Section {
                Toggle("I understand this is a study aid, not legal advice", isOn: $disclaimerAccepted)
            }

            Section {
                Button("Save") {
                    saveConfiguration()
                }
                .disabled(!configuration.isValid)

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(palette.danger)
                        .accessibilityLabel("Incomplete configuration: \(validationMessage)")
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
    }

    private var validationMessage: String? {
        switch configuration.validationError() {
        case .missingFilingDate:
            "Choose a filing date to continue."
        case .filingDateInFuture:
            "The filing date can't be in the future."
        case .missingTestVersion:
            "Select a test version to continue."
        case .missingStudyLanguage:
            "Choose a study support language."
        case .disclaimerNotAccepted:
            "Accept the study aid notice to save your configuration."
        case .selectedVersionDoesNotMatchFilingDate(let expected, let actual):
            "The selected version (\(actual.displayName)) doesn't match your filing date (\(expected.displayName))."
        case nil:
            nil
        }
    }

    private var title: String {
        savedConfigurations.first == nil ? "Test Configuration" : "Edit Configuration"
    }

    private var versionTitle: String {
        derivedVersion.displayName
    }

    private func saveConfiguration() {
        guard configuration.isValid else { return }

        if let existing = savedConfigurations.first {
            existing.update(from: configuration)
        } else {
            modelContext.insert(SavedOnboardingConfiguration(configuration: configuration))
        }
        try? modelContext.save()
        dismiss()
    }
}