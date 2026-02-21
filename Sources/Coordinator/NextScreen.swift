import Foundation

@available(iOS 17.0, *)

public enum NextScreen: Equatable {
    case push(any AppRoute)
    case pop
    case popToRoot
    case switchTab(Int)
    case presentSheet(any AppRoute)
    case presentFullScreen(any AppRoute)
    case dismissModal
}

public extension NextScreen {
    static func == (lhs: NextScreen, rhs: NextScreen) -> Bool {
        switch (lhs, rhs) {
        case (.pop, .pop),
            (.popToRoot, .popToRoot),
            (.dismissModal, .dismissModal):
            return true
        case let (.push(l), .push(r)):
            return AnyRoute(l) == AnyRoute(r)
        case let (.presentSheet(l), .presentSheet(r)):
            return AnyRoute(l) == AnyRoute(r)
        case let (.presentFullScreen(l), .presentFullScreen(r)):
            return AnyRoute(l) == AnyRoute(r)
        case let (.switchTab(l), .switchTab(r)):
            return l == r
        default:
            return false
        }
    }
}
