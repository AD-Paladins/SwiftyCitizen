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
    @State private var disclaimerAccepted: Bool
    @State private var shuffleQuestions: Bool
    @State private var dailyReviewGoal: Int

    init(configuration: OnboardingConfiguration? = nil) {
        _filingDate = State(initialValue: configuration?.filingDate ?? Date())
        _isSixtyFiveTwentyEligible = State(initialValue: configuration?.isSixtyFiveTwentyEligible ?? false)
        _disclaimerAccepted = State(initialValue: configuration?.disclaimerAccepted ?? false)
        _shuffleQuestions = State(initialValue: configuration?.shuffleQuestions ?? false)
        _dailyReviewGoal = State(initialValue: configuration?.dailyReviewGoal ?? 15)
    }

    private var configuration: OnboardingConfiguration {
        OnboardingConfiguration(
            filingDate: filingDate,
            selectedTestVersion: derivedVersion,
            isSixtyFiveTwentyEligible: isSixtyFiveTwentyEligible,
            disclaimerAccepted: disclaimerAccepted,
            shuffleQuestions: shuffleQuestions,
            dailyReviewGoal: effectiveDailyGoal
        )
    }

    private var derivedVersion: USCISTestVersion {
        isSixtyFiveTwentyEligible
            ? .sixtyFiveTwenty
            : (filingDate < OnboardingConfiguration.testVersionChangeDate ? .twoThousandEight : .twoThousandTwentyFive)
    }

    /// Preset daily-goal options for the current bank. Linked to the version so the 20-question
    /// 65/20 set caps at 20 while the larger banks keep the standard set.
    private var currentPresets: [Int] {
        TestConfiguration.dailyGoalPresets(for: derivedVersion)
    }

    /// The stored goal may not belong to the current bank's preset set (e.g. 45 on the 20-question
    /// 65/20 set). Fall back to the universal default every set accepts, so the ring and the saved
    /// value never use an impossible goal.
    private var effectiveDailyGoal: Int {
        currentPresets.contains(dailyReviewGoal) ? dailyReviewGoal : 15
    }

    private var validationMessage: String? {
        switch configuration.validationError() {
        case .missingFilingDate:
            "configMissingFilingDate"
        case .filingDateInFuture:
            "configFilingDateInFuture"
        case .missingTestVersion:
            "configMissingTestVersion"
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sm.value) {

                HStack(alignment: .center, spacing: Space.sm.value) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(palette.primary)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("configFilingDateSection")
                        .font(CivicText.bodyMD.font)
                        .foregroundStyle(palette.dimmed)
                }
                
                ConfigCard(topPadding: Space.xs.value) {
                    HStack(alignment: .top, spacing: Space.md.value) {
                        VStack(alignment: .leading, spacing: Space.sm.value) {
                            DatePicker(
                                "configN400FilingDateLabel",
                                selection: $filingDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .tint(palette.primary)
                            .foregroundStyle(palette.primary)
                            .font(CivicText.headlineSM.font)
                            
                            Text("configFilingDateNote")
                                .font(CivicText.bodySM.font)
                                .foregroundStyle(palette.dimmed)
                                .multilineTextAlignment(.leading)
                            
                            Text("configTestVersionNote")
                                .font(CivicText.bodySM.font)
                                .foregroundStyle(palette.dimmed)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }

                HStack(alignment: .center, spacing: Space.sm.value) {
                    Image(systemName: "person.badge.clock")
                        .foregroundStyle(palette.primary)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("configSpecialConsideration")
                        .font(CivicText.bodyMD.font)
                        .foregroundStyle(palette.dimmed)
                }

                ConfigCard(topPadding: Space.xs.value) {
                    VStack(alignment: .leading, spacing: Space.sm.value) {
                        HStack(alignment: .top, spacing: Space.md.value) {
                            Text("configSixtyTwentyToggle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tint(palette.primary)
                            .foregroundStyle(palette.primary)
                            .font(CivicText.headlineSM.font)

                            Toggle("", isOn: $isSixtyFiveTwentyEligible)
                                .frame(maxWidth: Space.twoXL.value * 2, alignment: .leading)
                                .tint(palette.primary)
                        }
                        
                        Text("configSixtyTwentyExemption")
                            .font(CivicText.bodySM.font)
                            .foregroundStyle(palette.dimmed)
                            .multilineTextAlignment(.leading)
                        
                    }
                }

                if configuration.testConfiguration != nil {
                    HStack(alignment: .center, spacing: Space.sm.value) {
                        Image(systemName: "questionmark.text.page")
                            .foregroundStyle(palette.primary)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Text("configQuestionaries")
                            .font(CivicText.bodyMD.font)
                            .foregroundStyle(palette.dimmed)
                    }
                    .padding(.bottom, Space.xs.value)
                    
                    ConfigurationSummaryView(configuration: configuration)
                }
                
                ConfigCard {
                    VStack(alignment: .leading, spacing: Space.sm.value) {
                        Text("configDailyGoalTitle")
                            .font(CivicText.headlineSM.font)
                            .foregroundStyle(palette.primary)
                            .tint(palette.primary)
                        Text("configDailyGoalNote")
                            .font(CivicText.bodySM.font)
                            .foregroundStyle(palette.dimmed)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: Space.sm.value) {
                            ForEach(currentPresets, id: \.self) { preset in
                                Button {
                                    dailyReviewGoal = preset
                                } label: {
                                    Text("\(preset)")
                                        .font(CivicText.labelSM.font.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(effectiveDailyGoal == preset ? palette.onSecondary : palette.ink)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            effectiveDailyGoal == preset ? palette.primary : palette.surfaceVariant,
                                            in: RoundedRectangle(cornerRadius: 12, style: .circular)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                ConfigCard {
                    HStack(alignment: .center, spacing: Space.md.value) {
                        Image(systemName: "shuffle")
                            .foregroundStyle(palette.primary)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        VStack(alignment: .leading, spacing: Space.sm.value) {
                            HStack(alignment: .top, spacing: Space.md.value) {
                                Text("configShuffleQuestions")
                                    .multilineTextAlignment(.leading)
                                    .tint(palette.primary)
                                    .foregroundStyle(palette.primary)
                                    .font(CivicText.headlineSM.font)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Toggle("", isOn: $shuffleQuestions)
                                    .frame(maxWidth: Space.twoXL.value * 2, alignment: .leading)
                                    .tint(palette.primary)
                            }
                            
                            Text("configShuffleQuestionsNote")
                                .font(CivicText.bodySM.font)
                                .foregroundStyle(palette.dimmed)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                
                ConfigCard {
                    Toggle("configDisclaimerToggle", isOn: $disclaimerAccepted)
                        .tint(palette.primary)
                }

                Text("configWhyThisMatters")
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.dimmed)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                SaveSection(isValid: configuration.isValid, validationMessage: validationMessage, save: saveConfiguration)
            }
            .padding(Space.lg.value)
        }
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: derivedVersion.rawValue) { _, _ in
            dailyReviewGoal = effectiveDailyGoal
        }
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

struct ConfigCard<Content: View>: View {
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    @ViewBuilder let content: Content
    
    init(
        topPadding: CGFloat = Space.lg.value,
        bottomPadding: CGFloat = Space.lg.value,
        @ViewBuilder content: () -> Content
    ) {
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.lg.value)
            .cardStyle()
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
    }
}

struct SaveSection: View {
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    let isValid: Bool
    let validationMessage: String?
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md.value) {
            PrimaryActionButton(title: "configSave", systemImage: "check", action: save)
                .disabled(!isValid)
            if let validationMessage {
                Text(validationMessage)
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.danger)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TestConfigurationView(configuration: OnboardingConfiguration(
             filingDate: Date(),
             selectedTestVersion: .twoThousandTwentyFive,
             isSixtyFiveTwentyEligible: false,
             disclaimerAccepted: true,
             shuffleQuestions: false
         ))
    }
    .environment(ThemeManager())
}
