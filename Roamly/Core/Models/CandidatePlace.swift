import Foundation
import CoreLocation

public struct CandidatePlace: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let category: DestinationCategory
    public let latitude: Double
    public let longitude: Double
    public let distanceMeters: Double
    public let address: String?
    public let poiCategoryRaw: String?
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: DestinationCategory,
        latitude: Double,
        longitude: Double,
        distanceMeters: Double = 0.0,
        address: String? = nil,
        poiCategoryRaw: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.distanceMeters = distanceMeters
        self.address = address
        self.poiCategoryRaw = poiCategoryRaw
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: CandidatePlace, rhs: CandidatePlace) -> Bool {
        lhs.id == rhs.id
    }
}
