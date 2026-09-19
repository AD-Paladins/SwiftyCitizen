import SwiftUI

struct SessionSummaryView: View {
    let answeredCount: Int
    let assessments: [SelfAssessment]
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

                Text("Session complete")
                    .font(.largeTitle.bold())
                    .foregroundStyle(palette.ink)
                    .padding(.top, 16)

                Text("You reviewed \(answeredCount) question\(answeredCount == 1 ? "" : "s").")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                VStack(spacing: 8) {
                    ForEach(SelfAssessment.allCases, id: \.self) { assessment in
                        summaryRow(assessment: assessment)
                    }
                }
                .padding(20)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 24)

                PrimaryActionButton(title: "Done", systemImage: "checkmark") {
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
        onFinish: {}
    )
    .environment(ThemeManager())
}