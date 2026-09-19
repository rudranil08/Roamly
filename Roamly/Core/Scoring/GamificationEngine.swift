import Foundation
import SwiftUI

public struct GamificationLevel: Sendable, Equatable {
    public let level: Int
    public let title: String
    public let currentThreshold: Int
    public let nextThreshold: Int
    public let nextTierTitle: String
    
    public init(
        level: Int,
        title: String,
        currentThreshold: Int,
        nextThreshold: Int,
        nextTierTitle: String
    ) {
        self.level = level
        self.title = title
        self.currentThreshold = currentThreshold
        self.nextThreshold = nextThreshold
        self.nextTierTitle = nextTierTitle
    }
    
    public func pointsToNextTier(from points: Int) -> Int {
        max(0, nextThreshold - points)
    }
    
    public func progressFraction(for points: Int) -> Double {
        guard nextThreshold > 0 else { return 1.0 }
        return min(1.0, max(0.0, Double(points) / Double(nextThreshold)))
    }
}

public struct AchievementBadge: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemIcon: String
    public let color: Color
    public let currentProgress: Int
    public let requiredProgress: Int
    public let pointsReward: Int
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        systemIcon: String,
        color: Color,
        currentProgress: Int,
        requiredProgress: Int,
        pointsReward: Int = 150
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.color = color
        self.currentProgress = currentProgress
        self.requiredProgress = requiredProgress
        self.pointsReward = pointsReward
    }
    
    public var isUnlocked: Bool {
        currentProgress >= requiredProgress
    }
    
    public var progressFraction: Double {
        min(1.0, Double(currentProgress) / Double(max(1, requiredProgress)))
    }
}

public struct GamificationStats: Sendable {
    public let currentStreakDays: Int
    public let longestStreakDays: Int
    public let totalCO2SavedKg: Double
    public let ecoFriendlyRatio: Double
    public let unlockedBadgeCount: Int
    public let totalBadgeCount: Int
}

public final class GamificationEngine: Sendable {
    public static let shared = GamificationEngine()
    
    public init() {}
    
    // MARK: - Single Source of Truth for Points
    
    public func calculateTotalPoints(from visits: [VisitEntity]) -> Int {
        let visitPoints = visits.reduce(0) { $0 + $1.calculatedScore }
        let badges = evaluateBadges(from: visits)
        let badgePoints = badges.filter { $0.isUnlocked }.reduce(0) { $0 + $1.pointsReward }
        return visitPoints + badgePoints
    }
    
    public func calculateTotalPoints(visitPoints: Int, badgeBonus: Int = 0) -> Int {
        max(0, visitPoints + badgeBonus)
    }
    
    // MARK: - Explorer Level Progression System
    
    private struct LevelTier {
        let level: Int
        let title: String
        let threshold: Int
        let nextThreshold: Int
        let nextTierTitle: String
    }
    
    private static let definedTiers: [LevelTier] = [
        LevelTier(level: 1, title: "Novice Scout", threshold: 0, nextThreshold: 300, nextTierTitle: "Pathfinder"),
        LevelTier(level: 2, title: "Pathfinder", threshold: 300, nextThreshold: 1000, nextTierTitle: "Trailblazer"),
        LevelTier(level: 3, title: "Trailblazer", threshold: 1000, nextThreshold: 2500, nextTierTitle: "Globetrotter"),
        LevelTier(level: 4, title: "Globetrotter", threshold: 2500, nextThreshold: 5000, nextTierTitle: "Master Wayfarer"),
        LevelTier(level: 5, title: "Master Wayfarer", threshold: 5000, nextThreshold: 10000, nextTierTitle: "Grand Adventurer"),
        LevelTier(level: 6, title: "Grand Adventurer", threshold: 10000, nextThreshold: 17500, nextTierTitle: "Vanguard Explorer"),
        LevelTier(level: 7, title: "Vanguard Explorer", threshold: 17500, nextThreshold: 27500, nextTierTitle: "Apex Voyager"),
        LevelTier(level: 8, title: "Apex Voyager", threshold: 27500, nextThreshold: 40000, nextTierTitle: "Legendary Pioneer"),
        LevelTier(level: 9, title: "Legendary Pioneer", threshold: 40000, nextThreshold: 55000, nextTierTitle: "Mythic Cartographer"),
        LevelTier(level: 10, title: "Mythic Cartographer", threshold: 55000, nextThreshold: 75000, nextTierTitle: "Sovereign Roamer"),
        LevelTier(level: 11, title: "Sovereign Roamer", threshold: 75000, nextThreshold: 100000, nextTierTitle: "Celestial Voyager"),
        LevelTier(level: 12, title: "Celestial Voyager", threshold: 100000, nextThreshold: 130000, nextTierTitle: "Chronicle Grandmaster"),
        LevelTier(level: 13, title: "Chronicle Grandmaster", threshold: 130000, nextThreshold: 165000, nextTierTitle: "Astral Pathfinder"),
        LevelTier(level: 14, title: "Astral Pathfinder", threshold: 165000, nextThreshold: 205000, nextTierTitle: "Zenith Nomad"),
        LevelTier(level: 15, title: "Zenith Nomad", threshold: 205000, nextThreshold: 250000, nextTierTitle: "Zenith Nomad (Tier 2)")
    ]
    
    public func calculateLevel(totalPoints: Int) -> GamificationLevel {
        let safePoints = max(0, totalPoints)
        
        // Scan predefined tiers in reverse to find the active tier
        for tier in Self.definedTiers.reversed() {
            if safePoints >= tier.threshold {
                if safePoints < tier.nextThreshold {
                    return GamificationLevel(
                        level: tier.level,
                        title: tier.title,
                        currentThreshold: tier.threshold,
                        nextThreshold: tier.nextThreshold,
                        nextTierTitle: tier.nextTierTitle
                    )
                }
                break
            }
        }
        
        // Beyond predefined tiers (points >= 250,000): dynamic calculation without upper bound
        let basePoints = 250000
        let step = 50000
        let extraIndex = (safePoints - basePoints) / step
        let level = 15 + extraIndex + 1
        let currentThreshold = basePoints + (extraIndex * step)
        let nextThreshold = currentThreshold + step
        let tierNum = extraIndex + 2
        let nextTierNum = tierNum + 1
        
        return GamificationLevel(
            level: level,
            title: "Zenith Nomad (Tier \(tierNum))",
            currentThreshold: currentThreshold,
            nextThreshold: nextThreshold,
            nextTierTitle: "Zenith Nomad (Tier \(nextTierNum))"
        )
    }
    
    public func calculateLevel(from totalPoints: Int) -> GamificationLevel {
        calculateLevel(totalPoints: totalPoints)
    }
    
    // MARK: - Streak Calculation
    
    public func calculateStreaks(from visits: [VisitEntity]) -> (current: Int, longest: Int) {
        guard !visits.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let visitDays = Set(visits.map { calendar.startOfDay(for: $0.capturedAt) }).sorted(by: >)
        
        guard let mostRecent = visitDays.first else { return (0, 0) }
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let isAlive = (mostRecent == today || mostRecent == yesterday)
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var isCalculatingCurrent = isAlive
        
        var previousDate: Date? = nil
        for day in visitDays {
            if let prev = previousDate {
                let dayDiff = calendar.dateComponents([.day], from: day, to: prev).day ?? 0
                if dayDiff == 1 {
                    tempStreak += 1
                } else {
                    if isCalculatingCurrent {
                        currentStreak = tempStreak
                        isCalculatingCurrent = false
                    }
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDate = day
        }
        
        if isCalculatingCurrent {
            currentStreak = tempStreak
        }
        longestStreak = max(longestStreak, tempStreak)
        
        return (current: currentStreak, longest: max(currentStreak, longestStreak))
    }
    
    public func calculateStreak(from visits: [VisitEntity]) -> (current: Int, longest: Int) {
        calculateStreaks(from: visits)
    }
    
    // MARK: - Eco & Sustainability Metrics
    
    public func calculateEcoMetrics(from visits: [VisitEntity]) -> (co2SavedKg: Double, ecoRatio: Double) {
        guard !visits.isEmpty else { return (0.0, 1.0) }
        
        var ecoDistanceKm = 0.0
        var ecoCount = 0
        
        for visit in visits {
            if visit.travelMode == .walking || visit.travelMode == .running || visit.travelMode == .cycling || visit.travelMode == .eBike {
                ecoDistanceKm += visit.distanceKm
                ecoCount += 1
            } else if visit.travelMode == .train || visit.travelMode == .bus || visit.travelMode == .tram || visit.travelMode == .metro {
                ecoDistanceKm += (visit.distanceKm * 0.5) // 50% relative CO2 credit for public transit
                ecoCount += 1
            }
        }
        
        // Approx 0.171 kg CO2 avoided per passenger-km compared to single-occupant petrol vehicle
        let co2Saved = ecoDistanceKm * 0.171
        let ratio = Double(ecoCount) / Double(visits.count)
        
        return (co2SavedKg: co2Saved, ecoRatio: ratio)
    }
    
    public func calculateEcoImpact(from visits: [VisitEntity]) -> (co2SavedKg: Double, ecoRatio: Double) {
        calculateEcoMetrics(from: visits)
    }
    
    // MARK: - Badges & Achievements
    
    public func evaluateBadges(from visits: [VisitEntity]) -> [AchievementBadge] {
        let walkingVisits = visits.filter { $0.travelMode == .walking || $0.travelMode == .running }.count
        let cyclingVisits = visits.filter { $0.travelMode == .cycling || $0.travelMode == .eBike }.count
        let cultureVisits = visits.filter { $0.category == .museum || $0.category == .worldHeritage || $0.category == .university }.count
        let natureVisits = visits.filter { $0.category == .nationalPark || $0.category == .publicPark || $0.category == .botanicalGarden }.count
        let verifiedVisits = visits.filter { $0.isVerified }.count
        let patronVisits = visits.filter { $0.spendingAmount > 0 }.count
        let streak = calculateStreaks(from: visits).current
        let totalDistance = visits.reduce(0.0) { $0 + $1.distanceKm }
        
        return [
            AchievementBadge(
                id: "first_journey",
                title: "First Step",
                subtitle: "Log your first verified travel destination",
                systemIcon: "figure.walk",
                color: Color.green,
                currentProgress: visits.count,
                requiredProgress: 1,
                pointsReward: 100
            ),
            AchievementBadge(
                id: "pioneer_walker",
                title: "Pioneer Walker",
                subtitle: "Log 5 walking or running journeys",
                systemIcon: "figure.walk.motion",
                color: Color.blue,
                currentProgress: walkingVisits,
                requiredProgress: 5,
                pointsReward: 150
            ),
            AchievementBadge(
                id: "pedal_voyager",
                title: "Pedal Voyager",
                subtitle: "Log 3 cycling or e-bike expeditions",
                systemIcon: "bicycle",
                color: Color.orange,
                currentProgress: cyclingVisits,
                requiredProgress: 3,
                pointsReward: 150
            ),
            AchievementBadge(
                id: "heritage_custodian",
                title: "Heritage Seeker",
                subtitle: "Visit 3 cultural or historic landmarks",
                systemIcon: "building.columns.fill",
                color: Color.purple,
                currentProgress: cultureVisits,
                requiredProgress: 3,
                pointsReward: 200
            ),
            AchievementBadge(
                id: "wilds_wanderer",
                title: "Wilds Wanderer",
                subtitle: "Explore 3 parks or natural reservations",
                systemIcon: "leaf.fill",
                color: Color.teal,
                currentProgress: natureVisits,
                requiredProgress: 3,
                pointsReward: 200
            ),
            AchievementBadge(
                id: "wayfarer_streak",
                title: "Wayfarer Rhythm",
                subtitle: "Maintain a 3-day continuous travel streak",
                systemIcon: "flame.fill",
                color: Color.red,
                currentProgress: streak,
                requiredProgress: 3,
                pointsReward: 250
            ),
            AchievementBadge(
                id: "truth_seeker",
                title: "Verified Explorer",
                subtitle: "Capture 5 photo-verified arrivals",
                systemIcon: "checkmark.seal.fill",
                color: Color.mint,
                currentProgress: verifiedVisits,
                requiredProgress: 5,
                pointsReward: 300
            ),
            AchievementBadge(
                id: "local_patron",
                title: "Local Patron",
                subtitle: "Support 2 local economy establishments",
                systemIcon: "creditcard.fill",
                color: Color.brown,
                currentProgress: patronVisits,
                requiredProgress: 2,
                pointsReward: 150
            ),
            AchievementBadge(
                id: "century_explorer",
                title: "Century Roamer",
                subtitle: "Travel 50 total kilometers away from base",
                systemIcon: "map.fill",
                color: Color.indigo,
                currentProgress: Int(totalDistance),
                requiredProgress: 50,
                pointsReward: 500
            )
        ]
    }
}
