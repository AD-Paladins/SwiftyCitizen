import SwiftUI

/// "About this content" — surfaces content provenance for the active test version: the official
/// source URL + revision and when USCIS last verified the bank. All values come from the active
/// version's loaded bank (`QuestionContent.sourceURL` / `sourceRevision` / `verificationDate`),
/// never invented. When the questions disagree on their source, the view reports the true number
/// of references instead of picking one arbitrarily.
struct ContentInformationView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    private var version: USCISTestVersion? { configuration.selectedTestVersion }

    /// The active version's bank. Errors are swallowed (same pattern as every other caller) and
    /// surface as "Not available" rather than crashing the settings screen.
    private var bank: [QuestionContent] {
        guard let version else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private var provenance: ContentProvenance {
        ContentProvenance.extract(from: bank)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg.value) {
                versionCard
                sourceCard
                verifiedCard
            }
            .padding(Space.lg.value)
        }
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
        .navigationTitle("contentInfoTitle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var versionCard: some View {
        SettingsCard {
            SettingsKeyValueRow(
                label: "contentInfoVersionLabel",
                value: LocalizedStringKey(version?.displayName ?? String(localized: "contentInfoUnavailable"))
            )
        }
    }

    private var sourceCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: Space.sm.value) {
                Text("contentInfoSourceLabel")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
                if let url = provenance.sourceURL {
                    Text(url.absoluteString)
                        .font(CivicText.bodySM.font)
                        .foregroundStyle(palette.ink)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("contentInfoUnavailable")
                        .font(CivicText.bodySM.font)
                        .foregroundStyle(palette.dimmed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if provenance.referenceCount > 1 {
                    let note = String(
                        format: String(localized: "contentInfoReferencesNote"),
                        provenance.referenceCount
                    )
                    Text(note)
                        .font(CivicText.bodySM.font)
                        .foregroundStyle(palette.dimmed)
                }
                revisionRow
            }
        }
    }

    private var revisionRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.md.value) {
            Text("contentInfoRevisionLabel")
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.ink)
            Spacer(minLength: Space.sm.value)
            Text(provenance.sourceRevision ?? String(localized: "contentInfoUnavailable"))
                .font(CivicText.labelMD.font)
                .foregroundStyle(palette.dimmed)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var verifiedCard: some View {
        SettingsCard {
            let formatted = provenance.verificationDate?
                .formatted(date: .abbreviated, time: .omitted)
                ?? String(localized: "contentInfoUnavailable")
            SettingsKeyValueRow(label: "contentInfoVerifiedLabel", value: LocalizedStringKey(formatted))
        }
    }
}

#Preview {
    NavigationStack {
        ContentInformationView(configuration: OnboardingConfiguration(
            filingDate: Date(timeIntervalSince1970: 1_700_000_000),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ))
    }
    .environment(ThemeManager())
}
