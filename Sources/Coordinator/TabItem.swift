import Foundation

@available(iOS 17.0, *)

public protocol TabItem: Hashable {
    var id: Int { get }
    var title: String { get }
    var systemImage: String { get }
    var initialRoute: any AppRoute { get }
}
