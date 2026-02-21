import SwiftUI
import Observation

@available(iOS 17.0, *)

public struct AppRootView: View {
    @Bindable var coordinator: AppTabCoordinator
    private let tabs: [any TabItem]

    public init(coordinator: AppTabCoordinator, tabs: [any TabItem]) {
        self._coordinator = Bindable(wrappedValue: coordinator)
        self.tabs = tabs
    }

    public var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(tabs, id: \.id) { tab in
                coordinator.view(for: tab.id)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab.id)
            }
        }
    }
}
