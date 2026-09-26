import SwiftUI

enum AppTab: Hashable {
    case home
    case study
    case practice
    case progress

    var title: String {
        switch self {
        case .home:
            String(localized: "appTabHome")
        case .study:
            String(localized: "appTabStudy")
        case .practice:
            String(localized: "appTabPractice")
        case .progress:
            String(localized: "appTabProgress")
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