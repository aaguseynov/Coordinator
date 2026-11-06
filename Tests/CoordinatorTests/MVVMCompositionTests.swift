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
        private weak var coordinator: AssemblyCoordinator<HomeAssembly>?

        init(service: Service, coordinator: AssemblyCoordinator<HomeAssembly>) {
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

    @MainActor final class Recorder { weak var model: HomeViewModel? }

    @MainActor struct HomeAssembly: ScreenAssembly {
        let recorder: Recorder

        @ViewBuilder
        func assemble(_ route: Route, container: DIContainer, coordinator: AssemblyCoordinator<Self>) -> some View {
            switch route {
            case .home:
                makeHome(container: container, coordinator: coordinator)
            case .detail:
                Text("Detail")
            }
        }

        private func makeHome(container: DIContainer, coordinator: AssemblyCoordinator<Self>) -> HomeView {
            let model = HomeViewModel(service: container.resolve(), coordinator: coordinator)
            recorder.model = model
            return HomeView(model: model)
        }
    }

    @Test func viewModelUsesDIAndNavigationWithoutVIP() {
        let container = DIContainer()
        container.register(Service.self) { _ in Service() }
        let recorder = Recorder()
        var coordinator: AssemblyCoordinator<HomeAssembly>? = AssemblyCoordinator(
            root: .home, container: container, assembly: HomeAssembly(recorder: recorder)
        )
        #expect(recorder.model != nil)
        recorder.model?.load()
        #expect(recorder.model?.title == "Loaded")
        recorder.model?.showDetail()
        #expect(coordinator?.path.map(\.route) == [.detail])
        coordinator = nil
        #expect(recorder.model == nil)
    }
}
