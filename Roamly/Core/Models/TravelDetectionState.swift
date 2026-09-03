import Foundation

public enum TravelDetectionState: String, Codable, CaseIterable, Sendable {
    case atHome = "AT_HOME"
    case leftHome = "LEFT_HOME"
    case traveling = "TRAVELING"
    case potentialVisit = "POTENTIAL_VISIT"
    case awaitingConfirmation = "AWAITING_CONFIRMATION"
    case photoCapture = "PHOTO_CAPTURE"
    case validating = "VALIDATING"
    case confirmed = "CONFIRMED"
    case scoring = "SCORING"
    
    public var displayTitle: String {
        switch self {
        case .atHome: return "At Base"
        case .leftHome: return "Left Base"
        case .traveling: return "In Transit"
        case .potentialVisit: return "Destination Detected"
        case .awaitingConfirmation: return "Awaiting Photo"
        case .photoCapture: return "Capturing Proof"
        case .validating: return "Verifying Visit"
        case .confirmed: return "Visit Confirmed"
        case .scoring: return "Scoring & Logging"
        }
    }
    
    public var statusDescription: String {
        switch self {
        case .atHome:
            return "Resting within your home geofence. GPS hardware is idle."
        case .leftHome:
            return "Boundary crossed. Transitioning to travel monitoring."
        case .traveling:
            return "Actively moving away from home base."
        case .potentialVisit:
            return "Stationary dwell detected outside your home zone."
        case .awaitingConfirmation:
            return "Take an in-app photo to confirm and log this visit."
        case .photoCapture:
            return "Acquiring live camera frame and sensor telemetry."
        case .validating:
            return "Executing spatial, temporal, and anti-tamper checks."
        case .confirmed:
            return "Visit authenticated. Select travel mode and spending."
        case .scoring:
            return "Computing travel points and persisting to logbook."
        }
    }
    
    public var badgeColorName: String {
        switch self {
        case .atHome: return "green"
        case .leftHome: return "yellow"
        case .traveling: return "blue"
        case .potentialVisit, .awaitingConfirmation: return "orange"
        case .photoCapture, .validating: return "purple"
        case .confirmed, .scoring: return "mint"
        }
    }
}
