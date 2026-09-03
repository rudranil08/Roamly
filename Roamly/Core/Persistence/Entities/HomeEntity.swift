import Foundation
import SwiftData

@Model
public final class HomeEntity {
    @Attribute(.unique) public var id: String
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var updatedAt: Date
    
    public init(
        id: String = "PRIMARY_HOME",
        name: String = "Home Base",
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        radiusMeters: Double = 150.0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.updatedAt = updatedAt
    }
}
