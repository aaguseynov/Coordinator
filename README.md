# Coordinator

A small SwiftUI navigation core with assembly-based screen construction and dependency injection. Architecture-independent: use it with MVVM, VIP, or other screen architectures.
Requires iOS 17+, Swift 6, and Xcode 16+.

## 2.0.0 (breaking API change)

Version 2.0.0 replaces the 1.x API. It does not change an application's pinned 1.x dependency until you explicitly migrate it. There is no required tab coordinator, ViewModel protocol, navigation observer, or ViewModel cache.

- `AssemblyCoordinator<Route>` owns a root screen, a typed navigation stack, and one modal presentation.
- `CoordinatorView` binds that state to `NavigationStack`, sheets, and full-screen covers.
- A `Screen` owns one assembled module and has a unique ID, even when two routes have the same value.
- `DIContainer`, `Scope`, and dependency-registration `Assembly` retain their existing API.

## Navigation and assembly

Routes describe destinations; assemblies construct modules. The builder runs once for the root at coordinator initialization and once per successful push or presentation, never from SwiftUI `body`.

```swift
import Coordinator
import SwiftUI

enum AuthRoute: Hashable {
    case login
    case registration
}

@MainActor
func makeAuthFlow(container: DIContainer) -> AssemblyCoordinator<AuthRoute> {
    AssemblyCoordinator(root: .login, container: container) { route, container, coordinator in
        switch route {
        case .login:
            // Replace with LoginAssembly(container: container).assemble(...).
            return AnyView(Text("Login"))
        case .registration:
            return AnyView(Text("Registration"))
        }
    }
}
```

Own the resulting coordinator with `@State` in the flow's root view; render it using `CoordinatorView(coordinator: coordinator)`. Do not recreate coordinators while evaluating `body`.

```swift
coordinator.push(.registration)
coordinator.pop()
coordinator.popToRoot()

coordinator.presentSheet(.registration)      // Bool: accepted or already presenting
coordinator.dismiss()
coordinator.presentFullScreen(.registration)
```

Only one modal is accepted at a time. Dismiss the existing modal before requesting another; a second request returns `false` without assembling a module. Modal content is not automatically wrapped in the parent's navigation stack. For a modal flow with its own pushes, assemble a child coordinator and its `CoordinatorView`.

The builder receives the owning coordinator for dependency injection. Assemblies must not navigate or read `root` while constructing that root. Use weak coordinator references in retained interactors and weak captures when the builder captures an owning feature coordinator.

## Screen architecture: MVVM, VIP, and others

The package defines no ViewModel, Interactor, Presenter, or ViewState protocols. Builders return SwiftUI views; the application chooses how those views are assembled and where navigation is requested.

With MVVM, an assembly injects services and a weak coordinator reference into a ViewModel. See [MVVMCompositionTests.swift](Tests/CoordinatorTests/MVVMCompositionTests.swift) for a compiled public-API example and lifetime verification.

With VIP, an assembly creates the module as follows:

```text
View -> Interactor -> Service
            |-> Presenter -> observable ViewState -> View
            |-> feature Coordinator -> AssemblyCoordinator
```

`LoginAssembly` resolves services from the container and constructs State, Presenter, Interactor, and View. Interactor and Presenter receive constructor dependencies; they do not resolve services themselves.

A feature `AuthCoordinator` can conform to a small `LoginCoordinating: AnyObject` protocol and contain an `AssemblyCoordinator<AuthRoute>`. The interactor holds a weak `LoginCoordinating` reference. Keep the owning feature coordinator alive above `CoordinatorView`.

See [VIPCompositionTests.swift](Tests/CoordinatorTests/VIPCompositionTests.swift) for a compiled public-API example, including assembly, DI, VIP, coordinator composition, and deallocation checks. Its authentication service is deliberately a synchronous demo, not production networking.

## Dependency injection

```swift
struct ServicesAssembly: Assembly {
    func assemble(into container: DIContainer) {
        container.register(APIClient.self, scope: .container) { _ in APIClient() }
        container.register(AuthService.self) { container in
            AuthService(client: container.resolve(APIClient.self))
        }
    }
}

let container = DIContainer()
container.apply(assemblies: [ServicesAssembly()])
```

| Scope | Lifetime |
|---|---|
| `.transient` | New value on each resolution |
| `.container` | Retained until container deallocation or re-registration |
| `.weak` | Same reference while another owner retains it; recreated afterward |

Weak scope requires a class instance, including class-backed protocol registrations. Re-registering a type clears both caches for that type. Missing registrations and invalid weak-scoped values fail fast. Register and resolve on one actor (normally `MainActor` at composition time); the container is not thread-safe. Avoid cyclic service dependencies and factories that strongly capture their container.

## Screen lifetime

The coordinator retains the assembled root, stack entries, and active modal. SwiftUI back gestures mutate the same `path` used by programmatic navigation; there is no shadow stack. Removed entries are no longer retained by the coordinator. SwiftUI may keep a disappearing screen alive until its transition completes. External owners and tasks can also extend a module's lifetime.

`Screen` can be copied as a normal value; retaining a copy also retains its content. It is not `Sendable`. Navigation and module assembly run on `MainActor`.

## App root and tabs

Create the container at the application composition root, outside any tab coordinator:

```text
AppCoordinator + shared DIContainer + session
  auth -> AuthCoordinator
  main -> MainCoordinator
            selected tab + independent section coordinators
```

An application's root switches auth/main based on its session. Tabs are ordinary app UI and do not own global dependency registration or other flows' modal navigation. Create a new main flow after logout/login instead of reusing previous authenticated navigation state.

## Validation

Run the `Coordinator` scheme's tests on an iOS simulator:

```sh
xcodebuild -scheme Coordinator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max,OS=17.2' test
```

Tests cover route identity, assembly frequency, stack mutations, modal exclusivity, stale dismissal protection, module lifetime, DI scopes, re-registration, and public-API MVVM and VIP composition. Stack mutation tests exercise the state contract; they are not end-to-end gesture/UI tests.

## Migration from 1.x

1. Move DI container ownership from `AppTabCoordinator` to the app composition root.
2. Replace `AppRoute.build` with a plain `Hashable` route enum and an assembly builder.
3. Replace `FlowViewModel.navigation` and `observe` with explicit feature-coordinator methods.
4. Replace `AppRootView` / flow hosts with `CoordinatorView`; keep tabs in app code.
5. Remove `ViewModelFactory`, `ViewModelStore`, `AnyRoute`, and `NextScreen` usage.

The package remains named `Coordinator`. Use version `2.0.0` or newer for this API; existing 1.x callers require migration.
