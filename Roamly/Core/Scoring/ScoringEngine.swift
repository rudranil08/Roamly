import Foundation

public struct ScoringBreakdown: Sendable, Identifiable {
    public var id = UUID()
    public let basePoints: Double
    public let categoryMultiplier: Double
    public let noveltyMultiplier: Double
    public let distancePoints: Double
    public let sustainabilityMultiplier: Double
    public let fraudMultiplier: Double
    public let finalScore: Int
}

public final class ScoringEngine: Sendable {
    public static let shared = ScoringEngine()
    
    private let baseDestinationPoints: Double = 100.0
    private let maxDistancePoints: Double = 50.0
    
    public init() {}
    
    public func calculateScore(
        travelMode: TravelMode,
        category: DestinationCategory,
        distanceKm: Double,
        lifetimeVisits: Int,
        fraudConfidence: Double = 1.0
    ) -> ScoringBreakdown {
        // 1. Novelty calculation
        let novelty: Double
        switch lifetimeVisits {
        case 0: novelty = 2.0
        case 1: novelty = 1.0
        case 2...4: novelty = 0.5
        default: novelty = 0.2
        }
        
        // 2. Sub-linear distance points capped at 50
        let safeDistance = (distanceKm.isNaN || distanceKm.isInfinite || distanceKm < 0) ? 0.0 : distanceKm
        let rawDistancePoints = 1.5 * sqrt(safeDistance)
        let distancePoints = min(maxDistancePoints, rawDistancePoints)
        
        // 3. Category significance
        let significance = category.significanceMultiplier
        
        // 4. Sustainability
        let sustainability = travelMode.sustainabilityMultiplier
        
        // 5. Fraud Factor
        let fraud: Double
        if fraudConfidence >= 0.85 {
            fraud = 1.0
        } else if fraudConfidence >= 0.50 {
            fraud = 0.5
        } else {
            fraud = 0.0
        }
        
        // 6. Final Score Calculation
        let subtotal = (baseDestinationPoints * significance * novelty) + distancePoints
        let finalScore = max(0, Int(round(subtotal * sustainability * fraud)))
        
        return ScoringBreakdown(
            basePoints: baseDestinationPoints,
            categoryMultiplier: significance,
            noveltyMultiplier: novelty,
            distancePoints: distancePoints,
            sustainabilityMultiplier: sustainability,
            fraudMultiplier: fraud,
            finalScore: finalScore
        )
    }
}
