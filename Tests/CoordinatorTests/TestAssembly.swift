import SwiftUI
import Coordinator

@MainActor
struct TestAssembly<Route: Hashable, Content: View>: ScreenAssembly {
    let build: @MainActor (Route, DIContainer, AssemblyCoordinator<Self>) -> Content

    func assemble(_ route: Route, container: DIContainer, coordinator: AssemblyCoordinator<Self>) -> Content {
        build(route, container, coordinator)
    }
}

@MainActor
final class WeakReference<Value: AnyObject> {
    weak var value: Value?
    init(_ value: Value?) { self.value = value }
}
