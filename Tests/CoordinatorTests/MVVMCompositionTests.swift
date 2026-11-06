import Coordinator
import Observation
import SwiftUI
import Testing

/// The same public navigation API supports MVVM without Interactor/Presenter types.
@Suite @MainActor
struct MVVMCompositionTests {
    enum Route: Hashable { case home, detail }
    struct Service { func title() -> String { "Loaded" } }

    @MainActor @Observable
    final class HomeViewModel {
        var title = "Home"
        private let service: Service
        private weak var coordinator: AssemblyCoordinator<Route>?

        init(service: Service, coordinator: AssemblyCoordinator<Route>) {
            self.service = service
            self.coordinator = coordinator
        }

        func load() { title = service.title() }
        func showDetail() { coordinator?.push(.detail) }
    }

    struct HomeView: View {
        let model: HomeViewModel
        var body: some View {
            VStack {
                Text(model.title)
                Button("Detail") { model.showDetail() }
            }
        }
    }

    @Test func viewModelUsesDIAndNavigationWithoutVIP() {
        let container = DIContainer()
        container.register(Service.self) { _ in Service() }
        weak var model: HomeViewModel?
        var coordinator: AssemblyCoordinator<Route>? = AssemblyCoordinator(root: .home, container: container) { route, container, coordinator in
            switch route {
            case .home:
                let viewModel = HomeViewModel(service: container.resolve(), coordinator: coordinator)
                model = viewModel
                return AnyView(HomeView(model: viewModel))
            case .detail:
                return AnyView(Text("Detail"))
            }
        }
        #expect(model != nil)
        model?.load()
        #expect(model?.title == "Loaded")
        model?.showDetail()
        #expect(coordinator?.path.map(\.route) == [.detail])
        coordinator = nil
        #expect(model == nil)
    }
}
