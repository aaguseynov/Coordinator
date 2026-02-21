import Observation

@MainActor
@Observable
public final class ViewModelStore {
    
    private var isCompacting = false
    
    private var storage: [AnyRoute: WeakBox<AnyObject>] = [:] {
        didSet {
            guard !isCompacting else { return }
            compactDead()
        }
    }
    
    public func resolve<VM: FlowViewModel>(for route: AnyRoute, create: () -> VM) -> VM {
        if let box = storage[route], let existing = box.value as? VM {
            return existing
        }
        
        let new = create()
        storage[route] = WeakBox(new)
        return new
    }
    
    public func remove(for route: AnyRoute) {
        storage.removeValue(forKey: route)
    }
    
    public func removeAll() {
        storage.removeAll()
    }
    
    private func compactDead() {
        isCompacting = true
        storage.keys
            .filter { storage[$0]?.value == nil }
            .forEach { storage.removeValue(forKey: $0) }
        
        isCompacting = false
    }
}
