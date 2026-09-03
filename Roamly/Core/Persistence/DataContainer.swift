import Foundation
import SwiftData

public struct DataContainer {
    public static func create(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            HomeEntity.self,
            VisitEntity.self,
            SyncQueueEntity.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }
    
    @MainActor
    public static var preview: ModelContainer = {
        let container = create(inMemory: true)
        let context = container.mainContext
        
        let home = HomeEntity(
            name: "Home Base",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 150.0
        )
        context.insert(home)
        
        let sample1 = VisitEntity(
            placeName: "Golden Gate Park",
            categoryRaw: DestinationCategory.publicPark.rawValue,
            latitude: 37.7694,
            longitude: -122.4862,
            capturedAt: Date().addingTimeInterval(-86400),
            travelModeRaw: TravelMode.cycling.rawValue,
            spendingAmount: 0.0,
            calculatedScore: 755,
            distanceKm: 6.2,
            isVerified: true,
            isSynced: true
        )
        context.insert(sample1)
        
        let sample2 = VisitEntity(
            placeName: "San Francisco Museum of Modern Art",
            categoryRaw: DestinationCategory.museum.rawValue,
            latitude: 37.7857,
            longitude: -122.4011,
            capturedAt: Date().addingTimeInterval(-43200),
            travelModeRaw: TravelMode.metro.rawValue,
            spendingAmount: 25.0,
            calculatedScore: 1208,
            distanceKm: 4.1,
            isVerified: true,
            isSynced: false
        )
        context.insert(sample2)
        
        return container
    }()
}
