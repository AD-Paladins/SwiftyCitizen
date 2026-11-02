import Foundation
import SwiftData
import SwiftyCitizenCore

func resetSpacedRepetition(_ context: ModelContext) {
    let attempts = (try? context.fetch(FetchDescriptor<QuestionAttempt>())) ?? []
    if !attempts.isEmpty {
        attempts.forEach(context.delete)
        try? context.save()
    }
}
