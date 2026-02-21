import Foundation

public protocol Assembly {
    func assemble(into container: DIContainer)
}

extension DIContainer {
    public func apply(assemblies: [Assembly]) {
        assemblies.forEach { $0.assemble(into: self) }
    }
}
