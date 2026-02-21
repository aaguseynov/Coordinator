import SwiftUI
import Observation

@available(iOS 17.0, *)

@MainActor
@Observable
public final class AppFlowCoordinator {
    
    // MARK: - Public properties

    public var viewModelStore = ViewModelStore()
    public var navigationStore: NavigationStore
    
    public var presentedSheet: AnyRoute? = nil
    public var presentedFullscreen: AnyRoute? = nil
    
    private var navigationsRouteStack: [AnyRoute] = []
    
    // MARK: - Initializable properties
    
    public let viewModelFactory: ViewModelFactory
    private weak var parentCoordinator: AppTabCoordinator?
    private let initialRoute: any AppRoute
    
    public init(
        initialRoute: some AppRoute,
        parentCoordinator: AppTabCoordinator,
        navigationStore: NavigationStore = NavigationStore()
    ) {
        self.initialRoute = initialRoute
        self.navigationStore = navigationStore
        self.parentCoordinator = parentCoordinator
        self.viewModelFactory = ViewModelFactory(container: parentCoordinator.container)
    }
    
    public func start() -> some View {
        let initialKey = AnyRoute(initialRoute)
        return initialRoute.build(coordinator: self, key: initialKey)
            .navigationDestination(for: AnyRoute.self) { route in
                route.build(coordinator: self)
            }
    }
    
    public func observe(_ vm: FlowViewModel) {
        withObservationTracking {
            _ = vm.navigation
        } onChange: { [weak self, weak vm] in
            Task { @MainActor in
                guard let self, let vm else { return }
                self.handleNavigation(vm)
                self.observe(vm)
            }
        }
    }
    
    private func handleNavigation(_ vm: FlowViewModel) {
        guard let action = vm.navigation else { return }
        vm.navigation = nil
        
        switch action {
        case .push(let route):
            let any = AnyRoute(route)
            navigationStore.storeRoute(any)
            navigationsRouteStack.append(any)
            
        case .pop:
            if !navigationsRouteStack.isEmpty {
                let removed = navigationsRouteStack.removeLast()
                viewModelStore.remove(for: removed)
            }
            navigationStore.popRoute()
            
        case .popToRoot:
            for r in navigationsRouteStack { viewModelStore.remove(for: r) }
            navigationsRouteStack.removeAll()
            navigationStore.popToRoot()
            
        case .switchTab, .presentSheet, .presentFullScreen, .dismissModal:
            parentCoordinator?.handleNavigation(action, in: self)
        }
    }
    
    @MainActor
    func didUpdatePath(from old: NavigationPath, to new: NavigationPath) {
        guard new.count < old.count else { return }
        let diff = old.count - new.count
        
        for _ in 0..<diff {
            if !navigationsRouteStack.isEmpty {
                let removed = navigationsRouteStack.removeLast()
                viewModelStore.remove(for: removed)
            }
        }
    }
}
