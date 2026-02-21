import SwiftUI

@available(iOS 17.0, *)

public struct RouteView: View {
    private let make: () -> AnyView
    private let identity: AnyHashable
    
    public init<V: View>(_ build: @escaping () -> V, id: AnyHashable) {
        self.make = { AnyView(build()) }
        self.identity = id
    }
    
    public var body: some View {
        make().id(identity)
    }
}
