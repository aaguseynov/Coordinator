# Coordinator

A lightweight, type-safe navigation framework for SwiftUI applications using the Coordinator pattern with built-in Dependency Injection.

## Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aaguseynov/Coordinator.git", from: "1.0.0")
]
```

Or add it directly in Xcode via **File → Add Package Dependencies**.

## Features

- **Coordinator Pattern** — Clean separation of navigation logic from views
- **Type-Safe Routing** — Compile-time checked navigation with `AppRoute` protocol
- **Tab Navigation** — Built-in support for `TabView` with independent navigation stacks
- **Modal Presentation** — Sheets and fullscreen covers with coordinator integration
- **Dependency Injection** — Lightweight DI container with multiple scopes
- **ViewModel Lifecycle** — Automatic ViewModel management tied to navigation stack
- **Observation-Ready** — Built with Swift's `@Observable` macro for seamless SwiftUI integration

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     AppRootView                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              AppTabCoordinator                    │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │  │
│  │  │ FlowCoord 1 │  │ FlowCoord 2 │  │ FlowCoord │  │  │
│  │  │ (Tab 1)     │  │ (Tab 2)     │  │ (Tab N)   │  │  │
│  │  └─────────────┘  └─────────────┘  └───────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │                  DIContainer                      │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Define Your Routes

```swift
import Coordinator

enum HomeRoute: AppRoute {
    case home
    case detail(id: String)
    case settings
    
    @MainActor
    func build(coordinator: AppFlowCoordinator, key: AnyRoute) -> RouteView {
        RouteView({
            switch self {
            case .home:
                HomeView(viewModel: coordinator.viewModelFactory.make(
                    HomeViewModel.self,
                    key: key,
                    store: coordinator.viewModelStore
                ) { container in
                    HomeViewModel(service: container.resolve())
                })
            case .detail(let id):
                DetailView(id: id)
            case .settings:
                SettingsView()
            }
        }, id: key)
    }
}
```

### 2. Create Your ViewModel

```swift
import Coordinator
import Observation

@Observable
final class HomeViewModel: FlowViewModel {
    var navigation: NextScreen?
    
    private let service: HomeService
    
    init(service: HomeService) {
        self.service = service
    }
    
    func showDetail(id: String) {
        navigation = .push(HomeRoute.detail(id: id))
    }
    
    func showSettings() {
        navigation = .presentSheet(HomeRoute.settings)
    }
}
```

### 3. Set Up Dependency Injection

```swift
import Coordinator

struct ServicesAssembly: Assembly {
    func assemble(into container: DIContainer) {
        container.register(HomeService.self, scope: .container) { _ in
            HomeServiceImpl()
        }
        
        container.register(APIClient.self, scope: .transient) { _ in
            APIClient()
        }
    }
}
```

### 4. Configure Tabs

```swift
import Coordinator

let tabs: [TabDescriptor] = [
    TabDescriptor(
        id: 0,
        title: "Home",
        systemImage: "house",
        initialRoute: HomeRoute.home
    ),
    TabDescriptor(
        id: 1,
        title: "Profile",
        systemImage: "person",
        initialRoute: ProfileRoute.profile
    )
]
```

### 5. Initialize the App

```swift
import SwiftUI
import Coordinator

@main
struct MyApp: App {
    @State private var coordinator = AppTabCoordinator(
        tabs: tabs,
        assemblies: [ServicesAssembly()]
    )
    
    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator, tabs: tabs)
        }
    }
}
```

## Navigation Actions

The `NextScreen` enum provides all navigation actions:

| Action | Description |
|--------|-------------|
| `.push(route)` | Push a new screen onto the navigation stack |
| `.pop` | Pop the current screen |
| `.popToRoot` | Pop to the root of the current tab |
| `.switchTab(id)` | Switch to another tab |
| `.presentSheet(route)` | Present a sheet modal |
| `.presentFullScreen(route)` | Present a fullscreen modal |
| `.dismissModal` | Dismiss the current modal |

## Dependency Injection Scopes

| Scope | Behavior |
|-------|----------|
| `.transient` | New instance created on every resolve |
| `.container` | Singleton — shared instance for the container lifetime |
| `.weak` | Cached with weak reference — recreated when deallocated |

## Core Components

| Component | Purpose |
|-----------|---------|
| `AppTabCoordinator` | Manages tabs and their flow coordinators |
| `AppFlowCoordinator` | Handles navigation within a single flow/tab |
| `AppRoute` | Protocol for defining navigable screens |
| `FlowViewModel` | Protocol for ViewModels with navigation capability |
| `DIContainer` | Dependency injection container |
| `Assembly` | Protocol for registering dependencies |
| `ViewModelStore` | Manages ViewModel lifecycle per route |
| `NavigationStore` | Wraps SwiftUI's `NavigationPath` |

## License

MIT License. See [LICENSE](LICENSE) for details.
