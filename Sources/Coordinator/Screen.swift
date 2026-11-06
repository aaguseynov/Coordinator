import SwiftUI

/// A single assembled module. Equal routes still get distinct screen identities.
public struct Screen<Route: Hashable>: Identifiable, Hashable {
    public let id: UUID
    public let route: Route
    let content: AnyView

    @MainActor
    init(route: Route, content: AnyView) {
        self.id = UUID()
        self.route = route
        self.content = content
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
