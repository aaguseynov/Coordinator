import Observation
import SwiftUI

/// A navigation flow independent of tabs, parent coordinators, and screen architecture.
@MainActor
@Observable
public final class AssemblyCoordinator<Route: Hashable> {
    public typealias Builder = @MainActor (Route, DIContainer, AssemblyCoordinator<Route>) -> AnyView

    public let container: DIContainer
    public var root: Screen<Route> {
        guard let rootScreen else {
            preconditionFailure("An assembly must not read root while assembling the root screen")
        }
        return rootScreen
    }
    /// SwiftUI writes this same array when the user navigates back interactively.
    public var path: [Screen<Route>] = []
    public private(set) var presentation: Presentation<Route>?

    @ObservationIgnored private let builder: Builder
    @ObservationIgnored private var rootScreen: Screen<Route>?

    public init(root: Route, container: DIContainer, assemble: @escaping Builder) {
        self.container = container
        self.builder = assemble
        self.rootScreen = makeScreen(root)
    }

    public func push(_ route: Route) {
        path.append(makeScreen(route))
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() { path.removeAll() }

    /// Returns false if this flow already owns a modal. Dismiss it before presenting another.
    @discardableResult
    public func presentSheet(_ route: Route) -> Bool { present(route, style: .sheet) }

    @discardableResult
    public func presentFullScreen(_ route: Route) -> Bool { present(route, style: .fullScreen) }

    public func dismiss() { presentation = nil }

    // A delayed SwiftUI dismissal must not clear a newer presentation.
    func dismiss(id: UUID) {
        guard presentation?.id == id else { return }
        dismiss()
    }

    private func present(_ route: Route, style: PresentationStyle) -> Bool {
        guard presentation == nil else { return false }
        presentation = Presentation(style: style, screen: makeScreen(route))
        return true
    }

    private func makeScreen(_ route: Route) -> Screen<Route> {
        Screen(route: route, content: builder(route, container, self))
    }
}
