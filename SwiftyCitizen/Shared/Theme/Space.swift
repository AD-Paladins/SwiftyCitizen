import SwiftUI

enum Space {
    case xs
    case sm
    case md
    case lg
    case xl
    case twoXL

    var value: CGFloat {
        switch self {
        case .xs:
            return 4
        case .sm:
            return 8
        case .md:
            return 16
        case .lg:
            return 20
        case .xl:
            return 28
        case .twoXL:
            return 40
        }
    }
}

extension View {
    func padding(_ space: Space) -> some View {
        self.padding(space.value)
    }
}
