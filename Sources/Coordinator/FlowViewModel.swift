import Foundation

@available(iOS 17.0, *)

@MainActor
public protocol FlowViewModel: AnyObject, Sendable {
    var navigation: NextScreen? { get set }
}
