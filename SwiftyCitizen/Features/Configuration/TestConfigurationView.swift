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
          Section("config.filingDateSection") {
                 DatePicker("config.n400FilingDateLabel", selection: $filingDate, in: ...Date(), displayedComponents: .date)
                 Text("config.filingDateNote")
                     .font(.footnote)
                     .foregroundStyle(palette.dimmed)
             }

             Section("config.testVersionSection") {
                 Toggle("config.sixtyTwentyToggle", isOn: $isSixtyFiveTwentyEligible)
                 LabeledContent("config.selectedVersion", value: versionTitle)
             }

             Section("config.studyOptionsSection") {
                 Toggle("config.shuffleQuestions", isOn: $shuffleQuestions)
             }

             Section("config.studyLanguageSection") {
                 Picker("config.studySupportLabel", selection: $studyLanguage) {
                     Text("config.chooseALanguage").tag(nil as StudyLanguage?)
                     ForEach(StudyLanguage.allCases) { language in
                         Text(language.displayName).tag(language as StudyLanguage?)
                     }
                 }
             }

            if let testConfiguration = configuration.testConfiguration {
                 Section("config.yourStudySet") {
                     let unit = testConfiguration.questionBankCount == 1 ? String(localized: "config.questionBankValueSingular") : String(localized: "config.questionBankValuePlural")
                     LabeledContent("config.questionBank", value: "\(testConfiguration.questionBankCount) \(unit)")
                     LabeledContent("config.questionsAsked", value: "\(String(localized: "config.questionsAskedPrefix"))\(testConfiguration.maximumQuestionsAsked)")
                     LabeledContent("config.passingScore", value: "\(testConfiguration.passingScore) \(String(localized: "config.passingScoreValueSuffix"))")
                 }
             }

           Section {
                 Toggle("config.disclaimerToggle", isOn: $disclaimerAccepted)
             }

             Section {
                 Button("config.save") {
                     saveConfiguration()
                 }
                 .disabled(!configuration.isValid)

                 if let validationMessage {
                     Label(validationMessage, systemImage: "exclamationmark.circle")
                         .font(.footnote)
                         .foregroundStyle(palette.danger)
                         .accessibilityLabel("\(String(localized: "config.incompleteConfigPrefix"))\(validationMessage)")
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
             "config.missingFilingDate"
         case .filingDateInFuture:
             "config.filingDateInFuture"
         case .missingTestVersion:
             "config.missingTestVersion"
         case .missingStudyLanguage:
             "config.missingStudyLanguage"
         case .disclaimerNotAccepted:
             "config.disclaimerNotAccepted"
         case .selectedVersionDoesNotMatchFilingDate(let expected, let actual):
             "\(String(localized: "config.versionMismatchPrefix"))\(actual.displayName)\(String(localized: "config.versionMismatchSuffix"))\(expected.displayName)\(String(localized: "config.versionMismatchEnd"))"
         case nil:
             nil
         }
     }

   private var title: String {
         savedConfigurations.first == nil ? "config.titleNew" : "config.titleEdit"
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