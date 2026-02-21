import Foundation

@available(iOS 17.0, *)
public struct AnyRoute: Hashable {
    private let base: any AppRoute
    private let erasedHash: AnyHashable
    
    public init(_ base: any AppRoute) {
        self.base = base
        self.erasedHash = AnyHashable(base)
    }
    
    @MainActor
    public func build(coordinator: AppFlowCoordinator) -> RouteView {
        base.build(coordinator: coordinator, key: self)
    }
    
    public static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool { lhs.erasedHash == rhs.erasedHash }
    public func hash(into hasher: inout Hasher) { erasedHash.hash(into: &hasher) }
}

extension AnyRoute: Identifiable {
    public var id: AnyHashable { erasedHash }
}
