import SwiftUI

enum AppTab: Hashable {
    case home
    case study
    case practice
    case progress

    var title: String {
        switch self {
        case .home:
            "Home"
        case .study:
            "Study"
        case .practice:
            "Practice"
        case .progress:
            "Progress"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .study:
            "book"
        case .practice:
            "mic"
        case .progress:
            "chart.bar"
        }
    }
}