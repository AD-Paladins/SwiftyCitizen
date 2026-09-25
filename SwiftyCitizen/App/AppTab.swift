import SwiftUI

enum AppTab: Hashable {
    case home
    case study
    case practice
    case progress

    var title: String {
        switch self {
        case .home:
            String(localized: "app.tab.home")
        case .study:
            String(localized: "app.tab.study")
        case .practice:
            String(localized: "app.tab.practice")
        case .progress:
            String(localized: "app.tab.progress")
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