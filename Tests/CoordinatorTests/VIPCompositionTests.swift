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
        weak var weakFlow = flow
        weak var weakNavigation = flow?.navigation
        weak var weakInteractor = flow?.loginInteractor
        #expect(weakNavigation != nil)
        #expect(weakInteractor != nil)
        flow = nil
        #expect(weakFlow == nil)
        #expect(weakNavigation == nil)
        #expect(weakInteractor == nil)
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

        lazy var navigation = AssemblyCoordinator<AuthRoute>(root: .login, container: container) { [weak self] route, container, _ in
            guard let self else { return AnyView(EmptyView()) }
            switch route {
            case .login:
                let view = LoginAssembly(container: container).assemble(coordinator: self)
                self.loginInteractor = view.interactor
                self.loginState = view.state
                return AnyView(view)
            case .registration:
                return AnyView(Text("Registration"))
            }
        }

        func showRegistration() { navigation.push(.registration) }
    }
}
