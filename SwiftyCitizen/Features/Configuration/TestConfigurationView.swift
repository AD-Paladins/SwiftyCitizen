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
    @State private var shuffleQuestions: Bool

    init(configuration: OnboardingConfiguration? = nil) {
        _filingDate = State(initialValue: configuration?.filingDate ?? Date())
        _isSixtyFiveTwentyEligible = State(initialValue: configuration?.isSixtyFiveTwentyEligible ?? false)
        _studyLanguage = State(initialValue: configuration?.studyLanguage)
        _disclaimerAccepted = State(initialValue: configuration?.disclaimerAccepted ?? false)
        _shuffleQuestions = State(initialValue: configuration?.shuffleQuestions ?? false)
    }

    private var configuration: OnboardingConfiguration {
        OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: derivedVersion,
            isSixtyFiveTwentyEligible: isSixtyFiveTwentyEligible,
            studyLanguage: studyLanguage,
            disclaimerAccepted: disclaimerAccepted,
            shuffleQuestions: shuffleQuestions
        )
    }

    private var derivedVersion: USCISTestVersion {
        isSixtyFiveTwentyEligible
            ? .sixtyFiveTwenty
            : (filingDate < OnboardingConfiguration.testVersionChangeDate ? .twoThousandEight : .twoThousandTwentyFive)
    }

    var body: some View {
        Form {
          Section("configFilingDateSection") {
                 DatePicker("configN400FilingDateLabel", selection: $filingDate, in: ...Date(), displayedComponents: .date)
                 Text("configFilingDateNote")
                     .font(.footnote)
                     .foregroundStyle(palette.dimmed)
             }

             Section("configTestVersionSection") {
                 Toggle("configSixtyTwentyToggle", isOn: $isSixtyFiveTwentyEligible)
                 LabeledContent("configSelectedVersion", value: versionTitle)
             }

             Section("configStudyOptionsSection") {
                 Toggle("configShuffleQuestions", isOn: $shuffleQuestions)
             }

             Section("configStudyLanguageSection") {
                 Picker("configStudySupportLabel", selection: $studyLanguage) {
                     Text(String(localized: "configChooseALanguage")).tag(nil as StudyLanguage?)
                     ForEach(StudyLanguage.allCases) { language in
                         Text(language.displayName).tag(language as StudyLanguage?)
                     }
                 }
             }

            if let testConfiguration = configuration.testConfiguration {
                 Section("configYourStudySet") {
                     let unit = testConfiguration.questionBankCount == 1 ? String(localized: "configQuestionBankValueSingular") : String(localized: "configQuestionBankValuePlural")
                     LabeledContent("configQuestionBank", value: "\(testConfiguration.questionBankCount) \(unit)")
                     LabeledContent("configQuestionsAsked", value: "\(String(localized: "configQuestionsAskedPrefix"))\(testConfiguration.maximumQuestionsAsked)")
                     LabeledContent("configPassingScore", value: "\(testConfiguration.passingScore) \(String(localized: "configPassingScoreValueSuffix"))")
                 }
             }

           Section {
                 Toggle("configDisclaimerToggle", isOn: $disclaimerAccepted)
             }

             Section {
                 Button("configSave") {
                     saveConfiguration()
                 }
                 .disabled(!configuration.isValid)

                 if let validationMessage {
                     Label(validationMessage, systemImage: "exclamationmark.circle")
                         .font(.footnote)
                         .foregroundStyle(palette.danger)
                         .accessibilityLabel("\(String(localized: "configIncompleteConfigPrefix"))\(validationMessage)")
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
             "configMissingFilingDate"
         case .filingDateInFuture:
             "configFilingDateInFuture"
         case .missingTestVersion:
             "configMissingTestVersion"
         case .missingStudyLanguage:
             "configMissingStudyLanguage"
         case .disclaimerNotAccepted:
             "configDisclaimerNotAccepted"
         case .selectedVersionDoesNotMatchFilingDate(let expected, let actual):
             "\(String(localized: "configVersionMismatchPrefix"))\(actual.displayName)\(String(localized: "configVersionMismatchSuffix"))\(expected.displayName)\(String(localized: "configVersionMismatchEnd"))"
         case nil:
             nil
         }
     }

   private var title: LocalizedStringKey {
         savedConfigurations.first == nil ? "configTitleNew" : "configTitleEdit"
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
