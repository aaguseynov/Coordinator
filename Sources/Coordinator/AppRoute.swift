import SwiftUI

@available(iOS 17.0, *)

@MainActor
public protocol AppRoute: Hashable {
    @ViewBuilder
    func build(coordinator: AppFlowCoordinator, key: AnyRoute) -> RouteView
}
