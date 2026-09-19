import Foundation
import CoreLocation
import MapKit
import Observation

@Observable
public final class DestinationDetectorService {
    public static let shared = DestinationDetectorService()
    
    public private(set) var isResolving: Bool = false
    public private(set) var primaryCandidate: CandidatePlace? = nil
    public private(set) var nearbyCandidates: [CandidatePlace] = []
    
    // Dwell Detection Telemetry
    public private(set) var isDwellTimerActive: Bool = false
    public private(set) var dwellElapsedSeconds: Int = 0
    public var dwellRequiredSeconds: Int = 180 // 3 minutes in production, can be set to 5 for test
    public private(set) var dwellStartCoordinate: CLLocationCoordinate2D? = nil
    
    private var dwellTimer: Timer? = nil
    private let geocoder = CLGeocoder()
    
    public init() {}
    
    // MARK: - Dwell State Machine
    
    public func startDwellTracking(at coordinate: CLLocationCoordinate2D, fastTestMode: Bool = false) {
        guard !isDwellTimerActive else { return }
        
        dwellStartCoordinate = coordinate
        isDwellTimerActive = true
        dwellElapsedSeconds = 0
        if fastTestMode {
            dwellRequiredSeconds = 5
        }
        
        dwellTimer?.invalidate()
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.dwellElapsedSeconds += 1
            
            if self.dwellElapsedSeconds >= self.dwellRequiredSeconds {
                self.completeDwell(at: coordinate)
            }
        }
    }
    
    public func cancelDwellTracking() {
        dwellTimer?.invalidate()
        dwellTimer = nil
        isDwellTimerActive = false
        dwellElapsedSeconds = 0
        dwellStartCoordinate = nil
    }
    
    public func completeDwell(at coordinate: CLLocationCoordinate2D) {
        cancelDwellTracking()
        
        Task { @MainActor in
            // Transition to potentialVisit
            AppState.shared.transitionTo(state: .potentialVisit)
            
            // Resolve venue via MapKit POI / Geocoder
            await resolveDestination(at: coordinate)
            
            // Recommend travel mode based on motion sensing
            AppState.shared.pendingTravelMode = MotionActivityService.shared.recommendedTravelMode
            
            // Transition to awaiting confirmation
            AppState.shared.transitionTo(state: .awaitingConfirmation)
            
            // Dispatch notification
            if let place = self.primaryCandidate {
                NotificationService.shared.notifyArrival(at: place.name, category: place.category)
            }
        }
    }
    
    // MARK: - Venue Resolution via MapKit & CLGeocoder
    
    public func resolveDestination(at coordinate: CLLocationCoordinate2D) async {
        await MainActor.run {
            self.isResolving = true
        }
        
        var resolvedPlaces: [CandidatePlace] = []
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // 1. Search with MKLocalPointsOfInterestRequest for named venues
        let searchRequest = MKLocalPointsOfInterestRequest(center: coordinate, radius: 250.0)
        searchRequest.pointOfInterestFilter = .includingAll
        
        if let searchResponse = try? await MKLocalSearch(request: searchRequest).start() {
            for item in searchResponse.mapItems {
                guard let name = item.name, !name.isEmpty else { continue }
                
                let poiCategory = item.pointOfInterestCategory
                let mappedCategory = mapMKCategory(poiCategory)
                let itemLocation = CLLocation(
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
                let dist = userLocation.distance(from: itemLocation)
                
                let address = [item.placemark.subThoroughfare, item.placemark.thoroughfare, item.placemark.locality]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                let candidate = CandidatePlace(
                    name: name,
                    category: mappedCategory,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude,
                    distanceMeters: dist,
                    address: address.isEmpty ? nil : address,
                    poiCategoryRaw: poiCategory?.rawValue
                )
                resolvedPlaces.append(candidate)
            }
        }
        
        // Sort by proximity
        resolvedPlaces.sort { $0.distanceMeters < $1.distanceMeters }
        
        // 2. Fallback to CLGeocoder if MapKit found no POI
        if resolvedPlaces.isEmpty {
            if let placemarks = try? await geocoder.reverseGeocodeLocation(userLocation) {
                if let placemark = placemarks.first {
                    let name = placemark.areasOfInterest?.first ?? placemark.name ?? placemark.subLocality ?? placemark.locality ?? "Explored Location"
                    let address = [placemark.name, placemark.locality, placemark.administrativeArea]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    
                    let fallbackCandidate = CandidatePlace(
                        name: name,
                        category: .uncategorized,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        distanceMeters: 0.0,
                        address: address
                    )
                    resolvedPlaces.append(fallbackCandidate)
                }
            }
        }
        
        // Final fallback if both returned empty
        if resolvedPlaces.isEmpty {
            let generic = CandidatePlace(
                name: "Explored Destination",
                category: .uncategorized,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                distanceMeters: 0.0,
                address: "Coordinates: \(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))"
            )
            resolvedPlaces.append(generic)
        }
        
        let primary = resolvedPlaces.first!
        let allCandidates = resolvedPlaces
        
        await MainActor.run {
            self.primaryCandidate = primary
            self.nearbyCandidates = allCandidates
            self.isResolving = false
            
            // Sync with AppState
            AppState.shared.candidatePlaceName = primary.name
            AppState.shared.candidateCategory = primary.category
            AppState.shared.candidateLatitude = primary.latitude
            AppState.shared.candidateLongitude = primary.longitude
            AppState.shared.nearbyCandidates = allCandidates
        }
    }
    
    public func selectCandidate(_ candidate: CandidatePlace) {
        self.primaryCandidate = candidate
        AppState.shared.candidatePlaceName = candidate.name
        AppState.shared.candidateCategory = candidate.category
        AppState.shared.candidateLatitude = candidate.latitude
        AppState.shared.candidateLongitude = candidate.longitude
    }
    
    // MARK: - Category Mapping
    
    private func mapMKCategory(_ category: MKPointOfInterestCategory?) -> DestinationCategory {
        guard let category = category else { return .uncategorized }
        
        switch category {
        case .museum:
            return .museum
        case .nationalPark:
            return .nationalPark
        case .park, .beach, .campground:
            return .publicPark
        case .zoo, .aquarium:
            return .botanicalGarden
        case .university, .school:
            return .university
        case .bakery, .brewery, .cafe, .restaurant, .winery, .foodMarket:
            return .foodMarket
        case .store, .musicVenue, .theater, .movieTheater, .nightlife:
            return .commercial
        case .airport, .publicTransport:
            return .transitHub
        case .landmark:
            return .worldHeritage
        default:
            return .uncategorized
        }
    }
}
