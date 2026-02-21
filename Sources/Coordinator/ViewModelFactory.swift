import Foundation

@MainActor
public final class ViewModelFactory {
    private let container: DIContainer
    
    public init(container: DIContainer) {
        self.container = container
    }
    
    public func make<VM: FlowViewModel>(
        _ type: VM.Type,
        key: AnyRoute,
        store: ViewModelStore,
        builder: (DIContainer) -> VM
    ) -> VM {
        store.resolve(for: key) {
            builder(container)
        }
    }
}
