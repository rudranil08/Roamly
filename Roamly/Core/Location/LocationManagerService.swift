import Foundation
import CoreLocation
import Observation

@Observable
public final class LocationManagerService: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationManagerService()
    
    public private(set) var currentLocation: CLLocation?
    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public private(set) var isInsideHomeGeofence: Bool = true
    public private(set) var distanceFromHomeMeters: Double = 0.0
    public private(set) var homeCoordinate: CLLocationCoordinate2D?
    public private(set) var homeRadiusMeters: Double = 150.0
    
    private let locationManager = CLLocationManager()
    public static let homeRegionIdentifier = "ROAMLY_HOME_GEOFENCE"
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50.0
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        self.authorizationStatus = locationManager.authorizationStatus
        
        setupMotionIntegration()
    }
    
    private func setupMotionIntegration() {
        MotionActivityService.shared.onStationaryDetected = { [weak self] in
            guard let self = self else { return }
            self.handleStationaryMotion()
        }
        
        MotionActivityService.shared.onMovementDetected = { [weak self] in
            guard let self = self else { return }
            self.handleMovementMotion()
        }
    }
    
    private func handleStationaryMotion() {
        guard !isInsideHomeGeofence else { return }
        
        let state = AppState.shared.currentState
        if state == .traveling || state == .leftHome {
            if let loc = currentLocation {
                DestinationDetectorService.shared.startDwellTracking(at: loc.coordinate)
            }
        }
    }
    
    private func handleMovementMotion() {
        guard !isInsideHomeGeofence else { return }
        
        // Moving again -> cancel dwell timer if it hasn't completed
        if DestinationDetectorService.shared.isDwellTimerActive {
            DestinationDetectorService.shared.cancelDwellTracking()
        }
        
        if AppState.shared.currentState == .leftHome || AppState.shared.currentState == .potentialVisit {
            AppState.shared.transitionTo(state: .traveling)
        }
    }
    
    public func requestPermissions() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    public func configureHomeGeofence(coordinate: CLLocationCoordinate2D, radiusMeters: Double) {
        self.homeCoordinate = coordinate
        self.homeRadiusMeters = max(150.0, radiusMeters)
        
        // Stop prior monitored regions
        for region in locationManager.monitoredRegions {
            if region.identifier == Self.homeRegionIdentifier {
                locationManager.stopMonitoring(for: region)
            }
        }
        
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            return
        }
        
        let circularRegion = CLCircularRegion(
            center: coordinate,
            radius: self.homeRadiusMeters,
            identifier: Self.homeRegionIdentifier
        )
        circularRegion.notifyOnEntry = true
        circularRegion.notifyOnExit = true
        
        locationManager.startMonitoring(for: circularRegion)
        locationManager.requestState(for: circularRegion)
        
        if let loc = currentLocation {
            let homeLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.distanceFromHomeMeters = loc.distance(from: homeLoc)
            self.isInsideHomeGeofence = self.distanceFromHomeMeters <= self.homeRadiusMeters
        }
    }
    
    public func startActiveTravelTracking() {
        // Battery-efficient tracking while traveling
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50.0
        locationManager.startUpdatingLocation()
    }
    
    public func stopActiveTravelTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    public func elevateAccuracyForVenuePinpoint() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestLocation()
    }
    
    public func requestSingleLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - Simulation Support
    
    public func simulateDeparture(distanceMeters: Double = 1800.0) {
        self.isInsideHomeGeofence = false
        self.distanceFromHomeMeters = distanceMeters
        let baseLat = homeCoordinate?.latitude ?? 37.7749
        let baseLon = homeCoordinate?.longitude ?? -122.4194
        let latOffset = distanceMeters / 111000.0
        let newLocation = CLLocation(latitude: baseLat + latOffset, longitude: baseLon)
        self.currentLocation = newLocation
        AppState.shared.currentTripDistanceKm = distanceMeters / 1000.0
        AppState.shared.candidateLatitude = baseLat + latOffset
        AppState.shared.candidateLongitude = baseLon
        AppState.shared.transitionTo(state: .traveling)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.startMonitoringSignificantLocationChanges()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        self.currentLocation = latest
        
        if let home = homeCoordinate {
            let homeLoc = CLLocation(latitude: home.latitude, longitude: home.longitude)
            self.distanceFromHomeMeters = latest.distance(from: homeLoc)
            self.isInsideHomeGeofence = self.distanceFromHomeMeters <= self.homeRadiusMeters
            
            let distanceKm = self.distanceFromHomeMeters / 1000.0
            AppState.shared.currentTripDistanceKm = distanceKm
            
            // Reactively transition state
            if !self.isInsideHomeGeofence {
                if AppState.shared.currentState == .atHome {
                    AppState.shared.transitionTo(state: .leftHome)
                } else if AppState.shared.currentState == .leftHome && distanceKm >= 0.3 {
                    AppState.shared.transitionTo(state: .traveling)
                }
            } else if self.isInsideHomeGeofence && AppState.shared.currentState != .atHome {
                // Returned home
                AppState.shared.resetTrip()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handled silently for intermittent GPS dropouts
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == Self.homeRegionIdentifier {
            self.isInsideHomeGeofence = true
            AppState.shared.resetTrip()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == Self.homeRegionIdentifier {
            self.isInsideHomeGeofence = false
            AppState.shared.transitionTo(state: .leftHome)
            startActiveTravelTracking()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region.identifier == Self.homeRegionIdentifier {
            switch state {
            case .inside:
                self.isInsideHomeGeofence = true
                if AppState.shared.currentState != .atHome {
                    AppState.shared.resetTrip()
                }
            case .outside:
                self.isInsideHomeGeofence = false
                if AppState.shared.currentState == .atHome {
                    AppState.shared.transitionTo(state: .leftHome)
                }
            case .unknown:
                break
            }
        }
    }
}
