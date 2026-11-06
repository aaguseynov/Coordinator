import SwiftUI

/// Builds statically typed screen content. Independent of the screen's architecture.
@MainActor
public protocol ScreenAssembly {
    associatedtype Route: Hashable
    associatedtype Content: View

    @ViewBuilder
    func assemble(
        _ route: Route,
        container: DIContainer,
        coordinator: AssemblyCoordinator<Self>
    ) -> Content
}
