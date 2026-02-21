import Foundation

@available(iOS 17.0, *)

public struct TabDescriptor: TabItem {
    public let id: Int
    public let title: String
    public let systemImage: String
    public let initialRoute: any AppRoute
    
    public init(id: Int, title: String, systemImage: String, initialRoute: any AppRoute) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.initialRoute = initialRoute
    }
    
    public static func == (lhs: TabDescriptor, rhs: TabDescriptor) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.systemImage == rhs.systemImage &&
        AnyRoute(lhs.initialRoute) == AnyRoute(rhs.initialRoute)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(AnyRoute(initialRoute))
    }
}
