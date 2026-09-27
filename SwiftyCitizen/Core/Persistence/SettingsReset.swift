import Foundation
import SwiftData

func resetSpacedRepetition(_ context: ModelContext) {
    let attempts = (try? context.fetch(FetchDescriptor<QuestionAttempt>())) ?? []
    if !attempts.isEmpty {
        attempts.forEach(context.delete)
        try? context.save()
    }
}
