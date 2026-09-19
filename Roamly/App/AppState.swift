import SwiftUI
import UIKit
import Observation

@Observable
public final class AppState {
    public static let shared = AppState()
    
    // Centralized User Settings
    public var settings = UserSettingsService.shared
    
    // Core State Machine
    public var currentState: TravelDetectionState = .atHome
    
    // Navigation
    public var selectedTab: Int = 0
    public var isPresentingCamera: Bool = false
    public var isPresentingHomeSetup: Bool = false
    public var isPresentingVerificationSheet: Bool = false
    
    // Active Journey Telemetry
    public var currentTripDistanceKm: Double = 0.0
    public var candidatePlaceName: String? = nil
    public var candidateCategory: DestinationCategory = .publicPark
    public var candidateLatitude: Double = 37.7694
    public var candidateLongitude: Double = -122.4862
    public var nearbyCandidates: [CandidatePlace] = []
    
    // Provisional Visit Data
    public var pendingCapturedImage: UIImage? = nil
    public var pendingTravelMode: TravelMode = .walking
    public var pendingSpending: Double = 0.0
    public var latestScoreBreakdown: ScoringBreakdown? = nil
    public var pendingAntiCheatResult: AntiCheatResult? = nil
    
    public init() {}
    
    // State Transitions
    public func transitionTo(state: TravelDetectionState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentState = state
        }
    }
    
    public func resetTrip() {
        self.currentTripDistanceKm = 0.0
        self.candidatePlaceName = nil
        self.pendingCapturedImage = nil
        self.latestScoreBreakdown = nil
        self.pendingAntiCheatResult = nil
        self.nearbyCandidates = []
        DestinationDetectorService.shared.cancelDwellTracking()
        NotificationService.shared.clearAllPendingArrivalNotifications()
        transitionTo(state: .atHome)
    }
}
