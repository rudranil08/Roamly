import Foundation
import SwiftData

@Model
public final class VisitEntity {
    @Attribute(.unique) public var id: UUID
    public var placeName: String
    public var categoryRaw: String
    public var latitude: Double
    public var longitude: Double
    public var capturedAt: Date
    public var travelModeRaw: String
    public var spendingAmount: Double
    public var spendingCurrency: String
    public var localPhotoPath: String?
    public var photoHash: String
    public var calculatedScore: Int
    public var distanceKm: Double
    public var isVerified: Bool
    public var isSynced: Bool
    
    public init(
        id: UUID = UUID(),
        placeName: String,
        categoryRaw: String = DestinationCategory.uncategorized.rawValue,
        latitude: Double,
        longitude: Double,
        capturedAt: Date = Date(),
        travelModeRaw: String = TravelMode.walking.rawValue,
        spendingAmount: Double = 0.0,
        spendingCurrency: String = UserSettingsService.shared.currencyCode,
        localPhotoPath: String? = nil,
        photoHash: String = "",
        calculatedScore: Int = 0,
        distanceKm: Double = 0.0,
        isVerified: Bool = true,
        isSynced: Bool = false
    ) {
        self.id = id
        self.placeName = placeName
        self.categoryRaw = categoryRaw
        self.latitude = latitude
        self.longitude = longitude
        self.capturedAt = capturedAt
        self.travelModeRaw = travelModeRaw
        self.spendingAmount = spendingAmount
        self.spendingCurrency = spendingCurrency
        self.localPhotoPath = localPhotoPath
        self.photoHash = photoHash
        self.calculatedScore = calculatedScore
        self.distanceKm = distanceKm
        self.isVerified = isVerified
        self.isSynced = isSynced
    }
    
    public var category: DestinationCategory {
        get { DestinationCategory(rawValue: categoryRaw) ?? .uncategorized }
        set { categoryRaw = newValue.rawValue }
    }
    
    public var travelMode: TravelMode {
        get { TravelMode(rawValue: travelModeRaw) ?? .walking }
        set { travelModeRaw = newValue.rawValue }
    }
}
