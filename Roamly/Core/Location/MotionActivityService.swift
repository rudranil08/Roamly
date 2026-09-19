import Foundation
import CoreMotion
import Observation

public enum SimulatedMotionType: String, CaseIterable, Identifiable, Sendable {
    case stationary = "Stationary"
    case walking = "Walking"
    case running = "Running"
    case cycling = "Cycling"
    case automotive = "Automotive / Transit"
    
    public var id: String { rawValue }
    
    public var systemIcon: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .automotive: return "car.fill"
        }
    }
}

@Observable
public final class MotionActivityService {
    public static let shared = MotionActivityService()
    
    public private(set) var currentActivityType: String = "Stationary"
    public private(set) var isStationary: Bool = true
    public private(set) var isWalking: Bool = false
    public private(set) var isRunning: Bool = false
    public private(set) var isAutomotive: Bool = false
    public private(set) var isCycling: Bool = false
    public private(set) var confidence: CMMotionActivityConfidence = .high
    
    public private(set) var stateEnteredAt: Date = Date()
    public private(set) var isHardwareAvailable: Bool = false
    public private(set) var isSimulated: Bool = false
    
    private let activityManager = CMMotionActivityManager()
    private let queue = OperationQueue()
    
    public var onStationaryDetected: (() -> Void)?
    public var onMovementDetected: (() -> Void)?
    
    public init() {
        queue.qualityOfService = .utility
        self.isHardwareAvailable = CMMotionActivityManager.isActivityAvailable()
    }
    
    public var recommendedTravelMode: TravelMode {
        if isCycling {
            return .cycling
        } else if isRunning {
            return .running
        } else if isWalking {
            return .walking
        } else if isAutomotive {
            return .bus
        } else {
            return .walking
        }
    }
    
    public func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            self.isHardwareAvailable = false
            self.currentActivityType = "Stationary (Simulator)"
            return
        }
        
        self.isHardwareAvailable = true
        activityManager.startActivityUpdates(to: queue) { [weak self] activity in
            guard let self = self, let act = activity else { return }
            
            DispatchQueue.main.async {
                self.handleActivityUpdate(
                    stationary: act.stationary,
                    walking: act.walking,
                    running: act.running,
                    automotive: act.automotive,
                    cycling: act.cycling,
                    confidence: act.confidence,
                    isSimulated: false
                )
            }
        }
    }
    
    public func stopMonitoring() {
        if isHardwareAvailable {
            activityManager.stopActivityUpdates()
        }
    }
    
    /// Developer simulation method for testing locomotion states on iPhone Simulator
    public func simulateMotion(type: SimulatedMotionType, confidence: CMMotionActivityConfidence = .high) {
        handleActivityUpdate(
            stationary: type == .stationary,
            walking: type == .walking,
            running: type == .running,
            automotive: type == .automotive,
            cycling: type == .cycling,
            confidence: confidence,
            isSimulated: true
        )
    }
    
    private func handleActivityUpdate(
        stationary: Bool,
        walking: Bool,
        running: Bool,
        automotive: Bool,
        cycling: Bool,
        confidence: CMMotionActivityConfidence,
        isSimulated: Bool
    ) {
        let previousStationary = self.isStationary
        
        self.isSimulated = isSimulated
        self.confidence = confidence
        self.isStationary = stationary
        self.isWalking = walking
        self.isRunning = running
        self.isAutomotive = automotive
        self.isCycling = cycling
        self.stateEnteredAt = Date()
        
        if walking {
            self.currentActivityType = "Walking"
        } else if running {
            self.currentActivityType = "Running"
        } else if cycling {
            self.currentActivityType = "Cycling"
        } else if automotive {
            self.currentActivityType = "Automotive / Transit"
        } else if stationary {
            self.currentActivityType = isSimulated ? "Stationary (Simulated)" : "Stationary"
        } else {
            self.currentActivityType = "In Transit"
        }
        
        // Notify state triggers
        if stationary && !previousStationary {
            onStationaryDetected?()
        } else if !stationary && previousStationary {
            onMovementDetected?()
        }
    }
}
