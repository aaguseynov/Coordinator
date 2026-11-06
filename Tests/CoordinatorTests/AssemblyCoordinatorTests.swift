import SwiftUI
import Testing
@testable import Coordinator

@Suite @MainActor
struct AssemblyCoordinatorTests {
    enum Route: Hashable { case login, details(Int) }

    private func makeCoordinator() -> AssemblyCoordinator<TestAssembly<Route, Text>> {
        AssemblyCoordinator(root: .login, container: DIContainer(), assembly: TestAssembly { route, _, _ in
            Text(String(describing: route))
        })
    }

    @Test func assemblesOncePerScreenAndPreservesRoot() {
        var builds = 0
        let coordinator = AssemblyCoordinator(root: Route.login, container: DIContainer(), assembly: TestAssembly { _, _, _ in
            builds += 1
            return EmptyView()
        })
        let rootID = coordinator.root.id
        _ = CoordinatorView(coordinator: coordinator).body
        _ = CoordinatorView(coordinator: coordinator).body
        #expect(builds == 1)
        coordinator.push(.details(1))
        #expect(builds == 2)
        coordinator.popToRoot()
        #expect(coordinator.root.id == rootID)
        #expect(builds == 2)
    }

    @Test func repeatedRoutesHaveIndependentIdentities() {
        let coordinator = makeCoordinator()
        coordinator.push(.details(1))
        coordinator.push(.details(1))
        #expect(coordinator.path[0].route == coordinator.path[1].route)
        #expect(coordinator.path[0] != coordinator.path[1])
        #expect(Set(coordinator.path).count == 2)
    }

    @Test func backAndPopToRootUseOneStack() {
        let coordinator = makeCoordinator()
        coordinator.pop()
        coordinator.push(.details(1))
        coordinator.push(.details(2))
        // This is the mutation performed by NavigationStack's binding on a back gesture.
        coordinator.path.removeLast()
        #expect(coordinator.path.map(\.route) == [.details(1)])
        coordinator.pop()
        #expect(coordinator.path.isEmpty)
        coordinator.push(.details(3))
        coordinator.popToRoot()
        #expect(coordinator.path.isEmpty)
    }

    @Test func modalExclusivityAndIdentity() {
        let coordinator = makeCoordinator()
        #expect(coordinator.presentSheet(.details(1)))
        let firstID = coordinator.presentation!.id
        #expect(coordinator.presentation?.style == .sheet)
        #expect(!coordinator.presentFullScreen(.details(2)))
        #expect(coordinator.presentation?.id == firstID)
        coordinator.dismiss()
        #expect(coordinator.presentFullScreen(.details(2)))
        #expect(coordinator.presentation?.style == .fullScreen)
        coordinator.dismiss(id: firstID)
        #expect(coordinator.presentation != nil)
        coordinator.dismiss(id: coordinator.presentation!.id)
        #expect(coordinator.presentation == nil)
    }

    @Test func inactiveModalBindingCannotDismissAnotherStyle() {
        let coordinator = makeCoordinator()
        coordinator.presentFullScreen(.details(1))
        let host = CoordinatorView(coordinator: coordinator)
        let inactive = host.modalBinding(for: .sheet)
        #expect(inactive.wrappedValue == nil)
        inactive.wrappedValue = nil
        #expect(coordinator.presentation?.style == .fullScreen)
        host.modalBinding(for: .fullScreen).wrappedValue = nil
        #expect(coordinator.presentation == nil)
    }

    @Test func oldModalBindingCannotDismissNewPresentation() {
        let coordinator = makeCoordinator()
        coordinator.presentSheet(.details(1))
        let binding = CoordinatorView(coordinator: coordinator).modalBinding(for: .sheet)
        coordinator.dismiss()
        coordinator.presentSheet(.details(2))
        binding.wrappedValue = nil
        #expect(coordinator.presentation?.screen.route == .details(2))
    }

    @Test func coordinatorForwardsProvidedContainer() {
        let container = DIContainer()
        var forwarded: DIContainer?
        let coordinator = AssemblyCoordinator(root: Route.login, container: container, assembly: TestAssembly { _, resolved, _ in
            forwarded = resolved
            return EmptyView()
        })
        #expect(coordinator.container === container)
        #expect(forwarded === container)
    }

    @Test func poppingReleasesModuleButKeepsRootAlive() {
        weak var rootProbe: Probe?
        weak var pushedProbe: Probe?
        let coordinator = AssemblyCoordinator(root: Route.login, container: DIContainer(), assembly: TestAssembly { route, _, _ in
            let probe = Probe()
            if route == .login { rootProbe = probe } else { pushedProbe = probe }
            return ProbeView(probe: probe)
        })
        coordinator.push(.details(1))
        #expect(rootProbe != nil)
        #expect(pushedProbe != nil)
        coordinator.path.removeLast()
        #expect(pushedProbe == nil)
        #expect(rootProbe != nil)
    }

    @Test func dismissingReleasesModalModule() {
        weak var modalProbe: Probe?
        let coordinator = AssemblyCoordinator(root: Route.login, container: DIContainer(), assembly: TestAssembly { route, _, _ in
            let probe = Probe()
            if route != .login { modalProbe = probe }
            return ProbeView(probe: probe)
        })
        coordinator.presentSheet(.details(1))
        #expect(modalProbe != nil)
        coordinator.dismiss()
        #expect(modalProbe == nil)
    }

    @Test func releasingFlowReleasesRootModule() {
        weak var rootProbe: Probe?
        var coordinator: AssemblyCoordinator<TestAssembly<Route, ProbeView>>? = AssemblyCoordinator(root: .login, container: DIContainer(), assembly: TestAssembly { _, _, _ in
            let probe = Probe()
            rootProbe = probe
            return ProbeView(probe: probe)
        })
        #expect(coordinator?.root.route == .login)
        coordinator = nil
        #expect(rootProbe == nil)
    }

    final class Probe {}
    struct ProbeView: View {
        let probe: Probe
        var body: some View { Text("Module") }
    }
}
