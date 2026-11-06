import SwiftUI

public enum PresentationStyle: Equatable {
    case sheet
    case fullScreen
}

/// Only one modal can be owned by a coordinator at a time.
public struct Presentation<Route: Hashable, Content: View>: Identifiable {
    public var id: UUID { screen.id }
    public let style: PresentationStyle
    public let screen: Screen<Route, Content>
}
