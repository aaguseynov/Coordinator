import Observation
import SwiftUI

/// A navigation flow independent of tabs, parent coordinators, and screen architecture.
@MainActor
@Observable
public final class AssemblyCoordinator<Assembler: ScreenAssembly> {
    public typealias Route = Assembler.Route
    public typealias Destination = Screen<Route, Assembler.Content>

    public let container: DIContainer
    public var root: Destination {
        guard let rootScreen else {
            preconditionFailure("An assembly must not read root while assembling the root screen")
        }
        return rootScreen
    }
    /// SwiftUI writes this same array when the user navigates back interactively.
    public var path: [Destination] = []
    public private(set) var presentation: Presentation<Route, Assembler.Content>?

    @ObservationIgnored private let assembly: Assembler
    @ObservationIgnored private var rootScreen: Destination?

    public init(root: Route, container: DIContainer, assembly: Assembler) {
        self.container = container
        self.assembly = assembly
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

    private func makeScreen(_ route: Route) -> Destination {
        Screen(route: route, content: assembly.assemble(route, container: container, coordinator: self))
    }
}
