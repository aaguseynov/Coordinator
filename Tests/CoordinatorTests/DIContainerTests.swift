import Testing
@testable import Coordinator

@Suite @MainActor
struct DIContainerTests {
    final class Service { let value: Int; init(_ value: Int = 0) { self.value = value } }
    protocol ServiceProtocol: AnyObject {}
    final class Implementation: ServiceProtocol {}

    @Test func transientCreatesNewInstances() {
        let container = DIContainer()
        container.register(Service.self) { _ in Service() }
        #expect(container.resolve(Service.self) !== container.resolve(Service.self))
    }

    @Test func containerScopeRetainsInstance() {
        let container = DIContainer()
        container.register(Service.self, scope: .container) { _ in Service() }
        let reference = WeakBox(container.resolve(Service.self))
        #expect(reference.value != nil)
        #expect(reference.value === container.resolve(Service.self))
    }

    @Test func weakScopeReusesThenRecreatesInstance() {
        let container = DIContainer()
        var builds = 0
        container.register(Service.self, scope: .weak) { _ in builds += 1; return Service() }
        var first: Service? = container.resolve(Service.self)
        let reference = WeakBox(first)
        #expect(first === container.resolve(Service.self))
        #expect(builds == 1)
        first = nil
        #expect(reference.value == nil)
        let second: Service = container.resolve()
        #expect(builds == 2)
        #expect(second === container.resolve(Service.self))
    }

    @Test func supportsWeakProtocolRegistration() {
        let container = DIContainer()
        container.register((any ServiceProtocol).self, scope: .weak) { _ in Implementation() }
        let first: any ServiceProtocol = container.resolve()
        let second: any ServiceProtocol = container.resolve()
        #expect(first === second)
    }

    @Test func reregistrationInvalidatesBothCaches() {
        for scope in [Scope.container, .weak] {
            let container = DIContainer()
            container.register(Service.self, scope: scope) { _ in Service(1) }
            let first: Service = container.resolve()
            container.register(Service.self, scope: scope) { _ in Service(2) }
            let replacement: Service = container.resolve()
            #expect(replacement !== first)
            #expect(replacement.value == 2)
        }
    }

    @Test func assembliesCanRegisterDependentServices() {
        struct Services: Assembly {
            func assemble(into container: DIContainer) {
                container.register(Int.self, scope: .container) { _ in 42 }
                container.register(Service.self) { Service($0.resolve(Int.self)) }
            }
        }
        let container = DIContainer()
        container.apply(assemblies: [Services()])
        #expect(container.resolve(Service.self).value == 42)
    }
}
