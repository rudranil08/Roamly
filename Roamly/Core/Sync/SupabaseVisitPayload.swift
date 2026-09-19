import Foundation

public struct SupabaseVisitPayload: Codable, Sendable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let placeName: String
    public let category: String
    public let travelMode: String
    public let spendingAmount: Double
    public let spendingCurrency: String
    public let photoHash: String
    public let calculatedScore: Int
    public let distanceKm: Double
    public let isVerified: Bool
    public let location: String // PostGIS WKT format: "POINT(lon lat)"
    public let latitude: Double
    public let longitude: Double
    public let capturedAt: String // ISO8601 string
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case placeName = "place_name"
        case category
        case travelMode = "travel_mode"
        case spendingAmount = "spending_amount"
        case spendingCurrency = "spending_currency"
        case photoHash = "photo_hash"
        case calculatedScore = "calculated_score"
        case distanceKm = "distance_km"
        case isVerified = "is_verified"
        case location
        case latitude
        case longitude
        case capturedAt = "captured_at"
    }
    
    public init(
        id: UUID,
        userId: UUID,
        placeName: String,
        category: String,
        travelMode: String,
        spendingAmount: Double,
        spendingCurrency: String,
        photoHash: String,
        calculatedScore: Int,
        distanceKm: Double,
        isVerified: Bool,
        latitude: Double,
        longitude: Double,
        capturedAtDate: Date
    ) {
        self.id = id
        self.userId = userId
        self.placeName = placeName
        self.category = category
        self.travelMode = travelMode
        self.spendingAmount = spendingAmount
        self.spendingCurrency = spendingCurrency
        self.photoHash = photoHash
        self.calculatedScore = calculatedScore
        self.distanceKm = distanceKm
        self.isVerified = isVerified
        self.latitude = latitude
        self.longitude = longitude
        // PostGIS uses "POINT(longitude latitude)" (standard WKT coordinate order)
        self.location = String(format: "POINT(%.7f %.7f)", longitude, latitude)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.capturedAt = formatter.string(from: capturedAtDate)
    }
    
    public static func from(visit: VisitEntity, userId: UUID) -> SupabaseVisitPayload {
        SupabaseVisitPayload(
            id: visit.id,
            userId: userId,
            placeName: visit.placeName,
            category: visit.categoryRaw,
            travelMode: visit.travelModeRaw,
            spendingAmount: visit.spendingAmount,
            spendingCurrency: visit.spendingCurrency,
            photoHash: visit.photoHash,
            calculatedScore: visit.calculatedScore,
            distanceKm: visit.distanceKm,
            isVerified: visit.isVerified,
            latitude: visit.latitude,
            longitude: visit.longitude,
            capturedAtDate: visit.capturedAt
        )
    }
}
