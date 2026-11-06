import Foundation

public enum Scope {
    /// always new
    case transient
    /// singleton
    case container
    // weak-cached
    case weak
}

/// Configure and resolve this container on one actor; it is not thread-safe.
public final class DIContainer {
    private struct Registration {
        let scope: Scope
        let factory: (DIContainer) -> Any
    }
    
    private var registrations: [ObjectIdentifier: Registration] = [:]
    private var strongStorage: [ObjectIdentifier: Any] = [:]
    private var weakStorage: [ObjectIdentifier: WeakBox<AnyObject>] = [:]
    
    public init() {}
    
    public func register<T>(
        _ type: T.Type = T.self,
        scope: Scope = .transient,
        factory: @escaping (DIContainer) -> T
    ) {
        let key = ObjectIdentifier(type)
        strongStorage.removeValue(forKey: key)
        weakStorage.removeValue(forKey: key)
        registrations[key] = Registration(
            scope: scope,
            factory: { container in factory(container) }
        )
    }
    
    public func resolve<T>(_ type: T.Type = T.self) -> T {
        let key = ObjectIdentifier(type)
        
        guard let registration = registrations[key] else {
            fatalError("No registration for \(type)")
        }
        
        switch registration.scope {
        case .transient:
            return registration.factory(self) as! T
            
        case .container:
            if let existing = strongStorage[key] as? T {
                return existing
            }
            let instance = registration.factory(self) as! T
            strongStorage[key] = instance
            return instance
            
        case .weak:
            if let existing = weakStorage[key]?.value as? T {
                return existing
            }
            let instance = registration.factory(self) as! T
            precondition(Mirror(reflecting: instance).displayStyle == .class,
                         "Weak scope requires a reference type: \(type)")
            weakStorage[key] = WeakBox(instance as AnyObject)
            return instance
        }
    }
}
