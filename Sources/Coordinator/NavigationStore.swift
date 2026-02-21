import SwiftUI
import Observation

@available(iOS 17.0, *)

public protocol NavigationStoring: AnyObject {
    
    var navigationPath: NavigationPath { get set }
    
    func storeRoute(_ route: AnyRoute)
    func popRoute()
    func popToRoot()
}

@Observable
public class NavigationStore: NavigationStoring {
    
    public var navigationPath: NavigationPath
    
    public init(navigationPath: NavigationPath = NavigationPath()) {
        self.navigationPath = navigationPath
    }
    
    public func storeRoute(_ route: AnyRoute) {
        navigationPath.append(route)
    }
    
    public func popRoute() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    public func popToRoot() {
        let count = navigationPath.count
        guard count > 0 else { return }
        navigationPath.removeLast(count)
    }
}
