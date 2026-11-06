import SwiftUI

/// Own the coordinator above this view (usually with @State in the flow's root).
public struct CoordinatorView<Assembler: ScreenAssembly>: View {
    @Bindable private var coordinator: AssemblyCoordinator<Assembler>

    public init(coordinator: AssemblyCoordinator<Assembler>) {
        self.coordinator = coordinator
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.root.content
                .id(coordinator.root.id)
                .navigationDestination(for: Screen<Assembler.Route, Assembler.Content>.self) { screen in
                    screen.content.id(screen.id)
                }
        }
        .sheet(item: modalBinding(for: .sheet)) { presentation in
            presentation.screen.content.id(presentation.id)
        }
        .fullScreenCover(item: modalBinding(for: .fullScreen)) { presentation in
            presentation.screen.content.id(presentation.id)
        }
    }

    func modalBinding(for style: PresentationStyle) -> Binding<Presentation<Assembler.Route, Assembler.Content>?> {
        let id = coordinator.presentation.flatMap { $0.style == style ? $0.id : nil }
        return Binding(
            get: {
                guard coordinator.presentation?.style == style else { return nil }
                return coordinator.presentation
            },
            set: { value in
                if value == nil, let id { coordinator.dismiss(id: id) }
            }
        )
    }
}
