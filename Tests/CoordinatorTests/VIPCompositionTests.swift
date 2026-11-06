import Observation
import SwiftUI
import Testing
import Coordinator

/// Compiles a consumer module against the public API, without @testable access.
@Suite @MainActor
struct VIPCompositionTests {
    @Test func assemblyInjectsDependenciesAndInteractorNavigates() {
        let container = DIContainer()
        container.apply(assemblies: [ServicesAssembly()])
        let flow = AuthCoordinator(container: container)
        let navigation = flow.navigation
        let interactor = flow.loginInteractor!
        interactor.signIn()
        #expect(flow.loginState?.message == "Signed in")
        interactor.showRegistration()
        #expect(navigation.path.map(\.route) == [.registration])
    }

    @Test func composedCoordinatorDoesNotRetainItselfThroughModules() {
        let container = DIContainer()
        container.apply(assemblies: [ServicesAssembly()])
        var flow: AuthCoordinator? = AuthCoordinator(container: container)
        let weakFlow = WeakReference(flow)
        let weakNavigation = WeakReference(flow?.navigation)
        let weakInteractor = WeakReference(flow?.loginInteractor)
        #expect(weakNavigation.value != nil)
        #expect(weakInteractor.value != nil)
        flow = nil
        #expect(weakFlow.value == nil)
        #expect(weakNavigation.value == nil)
        #expect(weakInteractor.value == nil)
    }

    enum AuthRoute: Hashable { case login, registration }
    @MainActor protocol LoginCoordinating: AnyObject { func showRegistration() }
    protocol AuthService { func signIn() -> Bool }
    struct DemoAuthService: AuthService { func signIn() -> Bool { true } }
    struct ServicesAssembly: Assembly {
        func assemble(into container: DIContainer) {
            container.register((any AuthService).self) { _ in DemoAuthService() }
        }
    }

    @MainActor @Observable final class LoginState { var message = "" }
    @MainActor struct LoginPresenter {
        let state: LoginState
        func present(success: Bool) { state.message = success ? "Signed in" : "Try again" }
    }
    @MainActor final class LoginInteractor {
        let service: any AuthService
        let presenter: LoginPresenter
        weak var coordinator: (any LoginCoordinating)?
        init(service: any AuthService, presenter: LoginPresenter, coordinator: any LoginCoordinating) {
            self.service = service
            self.presenter = presenter
            self.coordinator = coordinator
        }
        func signIn() { presenter.present(success: service.signIn()) }
        func showRegistration() { coordinator?.showRegistration() }
    }
    struct LoginView: View {
        let state: LoginState
        let interactor: LoginInteractor
        var body: some View {
            VStack {
                Text(state.message)
                Button("Sign in") { interactor.signIn() }
                Button("Register") { interactor.showRegistration() }
            }
        }
    }
    @MainActor struct LoginAssembly {
        let container: DIContainer
        func assemble(coordinator: any LoginCoordinating) -> LoginView {
            let state = LoginState()
            let presenter = LoginPresenter(state: state)
            let interactor = LoginInteractor(
                service: container.resolve((any AuthService).self),
                presenter: presenter,
                coordinator: coordinator
            )
            return LoginView(state: state, interactor: interactor)
        }
    }
    @MainActor final class AuthCoordinator: LoginCoordinating {
        let container: DIContainer
        weak var loginInteractor: LoginInteractor?
        weak var loginState: LoginState?

        init(container: DIContainer) { self.container = container }

        lazy var navigation = AssemblyCoordinator(
            root: AuthRoute.login,
            container: container,
            assembly: AuthScreenAssembly(owner: self)
        )

        func showRegistration() { navigation.push(.registration) }
    }

    @MainActor struct AuthScreenAssembly: ScreenAssembly {
        weak var owner: AuthCoordinator?

        @ViewBuilder
        func assemble(_ route: AuthRoute, container: DIContainer, coordinator: AssemblyCoordinator<Self>) -> some View {
            switch route {
            case .login:
                if let owner { makeLogin(owner: owner, container: container) }
            case .registration:
                Text("Registration")
            }
        }

        private func makeLogin(owner: AuthCoordinator, container: DIContainer) -> LoginView {
            let view = LoginAssembly(container: container).assemble(coordinator: owner)
            owner.loginInteractor = view.interactor
            owner.loginState = view.state
            return view
        }
    }

}
