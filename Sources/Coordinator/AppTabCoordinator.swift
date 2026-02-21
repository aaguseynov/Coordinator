import SwiftUI
import Observation

@available(iOS 17.0, *)

@MainActor
@Observable
public final class AppTabCoordinator {
    
    let container: DIContainer = DIContainer()
    
    var selectedTab: Int
    
    private var tabs: [any TabItem]
    private var coordinators: [Int: AppFlowCoordinator] = [:]
    
    public init(
        tabs: [any TabItem],
        assemblies: [Assembly]
    ) {
        self.tabs = tabs
        self.selectedTab = tabs.first?.id ?? 0
        // registry dependencies
        container.apply(assemblies: assemblies)
        
        for tab in tabs {
            coordinators[tab.id] = AppFlowCoordinator(
                initialRoute: tab.initialRoute,
                parentCoordinator: self
            )
        }
    }
    
    @MainActor
    func handleNavigation(_ action: NextScreen, in flow: AppFlowCoordinator) {
        switch action {
        case .switchTab(let tabID):
            self.selectedTab = tabID
            
        case .presentSheet(let route):
            flow.presentedSheet = AnyRoute(route)
            
        case .presentFullScreen(let route):
            flow.presentedFullscreen = AnyRoute(route)
            
        case .dismissModal:
            flow.presentedSheet = nil
            flow.presentedFullscreen = nil
            
        default:
            break
        }
    }
    
    @ViewBuilder
    public func view(for tabID: Int) -> some View {
        if let coordinator = coordinators[tabID] {
            NavigationStack(
                path: Binding(
                    get: { coordinator.navigationStore.navigationPath },
                    set: { coordinator.navigationStore.navigationPath = $0 }
                )
            ){
                coordinator.start()
                    .sheet(item: Binding(
                        get: { coordinator.presentedSheet },
                        set: { coordinator.presentedSheet = $0 }
                    )) { sheetRoute in
                        sheetRoute.build(coordinator: coordinator)
                    }
                    .fullScreenCover(item: Binding(
                        get: { coordinator.presentedFullscreen },
                        set: { coordinator.presentedFullscreen = $0 }
                    )) { fullScreenRoute in
                        fullScreenRoute.build(coordinator: coordinator)
                    }
            }
            .onChange(of: coordinator.navigationStore.navigationPath) { oldValue, newValue in
                coordinator.didUpdatePath(from: oldValue, to: newValue)
            }
        }
    }
}
