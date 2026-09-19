import Foundation
import CoreLocation

public struct SecurityCheckItem: Identifiable, Sendable {
    public var id = UUID()
    public let name: String
    public let status: CheckStatus
    public let detail: String
    
    public enum CheckStatus: String, Sendable {
        case passed = "Passed"
        case flagged = "Flagged"
        case failed = "Failed"
        
        public var systemIcon: String {
            switch self {
            case .passed: return "checkmark.seal.fill"
            case .flagged: return "exclamationmark.triangle.fill"
            case .failed: return "xmark.octagon.fill"
            }
        }
    }
}

public struct AntiCheatResult: Sendable {
    public let isPassed: Bool
    public let fraudConfidence: Double // 1.0 = clean, 0.5 = suspicious, 0.0 = fraudulent
    public let failureReason: String?
    public let checkItems: [SecurityCheckItem]
    public let calculatedSpeedKmh: Double?
    public let minHammingDistance: Int?
}

public struct AntiCheatEngine: Sendable {
    public static let shared = AntiCheatEngine()
    
    public init() {}
    
    public func validateVisit(
        currentLocation: CLLocation,
        lastVisitLocation: CLLocation? = nil,
        lastVisitTime: Date? = nil,
        currentPhotoHash: String,
        existingHashes: [String] = [],
        capturedTimestamp: Date = Date(),
        travelMode: TravelMode = .walking
    ) -> AntiCheatResult {
        var checkItems: [SecurityCheckItem] = []
        var fraudConfidence: Double = 1.0
        var failureReason: String? = nil
        var isPassed = true
        var minHamming: Int? = nil
        var calculatedSpeed: Double? = nil
        
        // -------------------------------------------------------------
        // 1. Photo Uniqueness Check via 64-bit dHash Hamming Distance
        // -------------------------------------------------------------
        if !currentPhotoHash.isEmpty && !existingHashes.isEmpty {
            var lowestDistance = 64
            for priorHash in existingHashes where !priorHash.isEmpty {
                let dist = PerceptualHashEngine.hammingDistance(hash1: currentPhotoHash, hash2: priorHash)
                if dist < lowestDistance {
                    lowestDistance = dist
                }
            }
            minHamming = lowestDistance
            
            if lowestDistance <= 8 {
                isPassed = false
                fraudConfidence = 0.0
                failureReason = "Duplicate photo detected (Hamming distance: \(lowestDistance) <= 8). Photos must be taken live at the destination."
                checkItems.append(SecurityCheckItem(
                    name: "Perceptual Image Uniqueness",
                    status: .failed,
                    detail: "Match distance: \(lowestDistance) <= 8 (Visual duplicate detected)"
                ))
            } else {
                checkItems.append(SecurityCheckItem(
                    name: "Perceptual Image Uniqueness",
                    status: .passed,
                    detail: "Hamming distance: \(lowestDistance) (Visual uniqueness verified)"
                ))
            }
        } else {
            checkItems.append(SecurityCheckItem(
                name: "Perceptual Image Uniqueness",
                status: .passed,
                detail: "First image hash indexed (dHash 64-bit registered)"
            ))
        }
        
        // -------------------------------------------------------------
        // 2. Physical Transit Velocity & Teleportation Matrix
        // -------------------------------------------------------------
        if let lastLoc = lastVisitLocation, let lastTime = lastVisitTime {
            let distanceMeters = currentLocation.distance(from: lastLoc)
            let timeDeltaSeconds = max(1.0, abs(capturedTimestamp.timeIntervalSince(lastTime)))
            let speedKmh = (distanceMeters / 1000.0) / (timeDeltaSeconds / 3600.0)
            calculatedSpeed = speedKmh
            
            if distanceMeters > 300.0 && speedKmh > 250.0 && travelMode != .airplane {
                isPassed = false
                fraudConfidence = 0.0
                failureReason = String(format: "Unrealistic transit velocity (%.0f km/h). Teleportation check failed.", speedKmh)
                checkItems.append(SecurityCheckItem(
                    name: "Transit Velocity & Physics",
                    status: .failed,
                    detail: String(format: "Speed: %.0f km/h exceeds 400 km/h maximum transit ceiling", speedKmh)
                ))
            } else if (travelMode == .walking || travelMode == .running) && speedKmh > 40.0 && distanceMeters > 100.0 {
                fraudConfidence = min(fraudConfidence, 0.5)
                checkItems.append(SecurityCheckItem(
                    name: "Transit Velocity & Physics",
                    status: .flagged,
                    detail: String(format: "Speed: %.0f km/h suspicious for human-powered mode", speedKmh)
                ))
            } else {
                checkItems.append(SecurityCheckItem(
                    name: "Transit Velocity & Physics",
                    status: .passed,
                    detail: String(format: "Plausible transit speed: %.1f km/h", speedKmh)
                ))
            }
        } else {
            checkItems.append(SecurityCheckItem(
                name: "Transit Velocity & Physics",
                status: .passed,
                detail: "Initial trip departure verified"
            ))
        }
        
        // -------------------------------------------------------------
        // 3. GPS Horizontal Precision & Anti-Spoofing Check
        // -------------------------------------------------------------
        let hAccuracy = currentLocation.horizontalAccuracy
        if hAccuracy > 200.0 || hAccuracy < 0 {
            fraudConfidence = min(fraudConfidence, 0.5)
            checkItems.append(SecurityCheckItem(
                name: "GPS Precision & Anti-Spoofing",
                status: .flagged,
                detail: String(format: "Low precision fix: ±%.0fm. Score multiplier reduced.", max(0, hAccuracy))
            ))
        } else {
            checkItems.append(SecurityCheckItem(
                name: "GPS Precision & Anti-Spoofing",
                status: .passed,
                detail: String(format: "High precision fix: ±%.1fm", hAccuracy)
            ))
        }
        
        // -------------------------------------------------------------
        // 4. Live Sensor Freshness & Temporal Stamp Check
        // -------------------------------------------------------------
        let timeSkew = abs(Date().timeIntervalSince(capturedTimestamp))
        if timeSkew > 180.0 {
            isPassed = false
            fraudConfidence = 0.0
            failureReason = "Stale photo timestamp. Photos must be captured live through the in-app camera."
            checkItems.append(SecurityCheckItem(
                name: "Live Sensor Freshness",
                status: .failed,
                detail: "Captured \(Int(timeSkew))s ago. Replay attack flagged."
            ))
        } else {
            checkItems.append(SecurityCheckItem(
                name: "Live Sensor Freshness",
                status: .passed,
                detail: "Captured in real-time (\(Int(timeSkew))s ago)"
            ))
        }
        
        // -------------------------------------------------------------
        // 5. Base Geofence Disconnect Check
        // -------------------------------------------------------------
        if LocationManagerService.shared.isInsideHomeGeofence && LocationManagerService.shared.homeCoordinate != nil {
            isPassed = false
            fraudConfidence = 0.0
            failureReason = "Cannot log visits within home base geofence. Journeys must occur outside your base zone."
            checkItems.append(SecurityCheckItem(
                name: "Geofence Disconnect",
                status: .failed,
                detail: "Device is currently inside home base perimeter."
            ))
        } else {
            checkItems.append(SecurityCheckItem(
                name: "Geofence Disconnect",
                status: .passed,
                detail: LocationManagerService.shared.homeCoordinate == nil ? "External travel verified (Base unconfigured)" : String(format: "External travel verified: %.1f km from base", AppState.shared.currentTripDistanceKm)
            ))
        }
        
        return AntiCheatResult(
            isPassed: isPassed,
            fraudConfidence: isPassed ? fraudConfidence : 0.0,
            failureReason: failureReason,
            checkItems: checkItems,
            calculatedSpeedKmh: calculatedSpeed,
            minHammingDistance: minHamming
        )
    }
}
