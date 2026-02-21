import Foundation

public enum Scope {
    /// always new
    case transient
    /// singleton
    case container
    // weak-cached
    case weak
}

public final class DIContainer {
    private struct Registration {
        let scope: Scope
        let factory: (DIContainer) -> Any
    }
    
    private var registrations: [ObjectIdentifier: Registration] = [:]
    private var strongStorage: [ObjectIdentifier: Any] = [:]
    private var weakStorage: NSMapTable<AnyObject, AnyObject> = NSMapTable.weakToWeakObjects()
    
    public init() {}
    
    public func register<T>(
        _ type: T.Type = T.self,
        scope: Scope = .transient,
        factory: @escaping (DIContainer) -> T
    ) {
        registrations[ObjectIdentifier(type)] = Registration(
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
            if let existing = weakStorage.object(forKey: key as AnyObject) as? T {
                return existing
            }
            let instance = registration.factory(self) as! T
            weakStorage.setObject(instance as AnyObject, forKey: key as AnyObject)
            return instance
        }
    }
}
