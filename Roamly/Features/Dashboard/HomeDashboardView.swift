import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct HomeDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var homes: [HomeEntity]
    @Query private var visits: [VisitEntity]
    
    @State private var isShowingHomeSetup: Bool = false
    @State private var isShowingCamera: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var isShowingDirectConfirmation: Bool = false
    @State private var isShowingCloudSyncSheet: Bool = false
    @State private var isLabExpanded: Bool = false
    @State private var antiCheatAlert: String? = nil
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var selectedNearbyPlace: CandidatePlace? = nil
    
    private var primaryHome: HomeEntity? {
        homes.first
    }
    
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        default: return "GOOD EVENING"
        }
    }
    
    private var totalPoints: Int {
        visits.reduce(0) { $0 + $1.calculatedScore }
    }
    
    private var totalDistanceKm: Double {
        visits.reduce(0.0) { $0 + $1.distanceKm }
    }
    
    private var currentDestinationName: String {
        if let candidate = appState.candidatePlaceName, !candidate.isEmpty {
            return candidate
        }
        if let first = appState.nearbyCandidates.first {
            return first.name
        }
        if let lastVisit = visits.sorted(by: { $0.capturedAt > $1.capturedAt }).first {
            return lastVisit.placeName
        }
        return primaryHome?.name ?? "Base Camp"
    }
    
    private var currentDestinationCategory: DestinationCategory {
        appState.candidateCategory
    }
    
    private var currentCenterCoordinate: CLLocationCoordinate2D {
        if let loc = LocationManagerService.shared.currentLocation?.coordinate {
            return loc
        }
        if let home = primaryHome {
            return CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
        }
        return CLLocationCoordinate2D(latitude: appState.candidateLatitude, longitude: appState.candidateLongitude)
    }
    
    private var placesForYou: [CandidatePlace] {
        if !appState.nearbyCandidates.isEmpty {
            return appState.nearbyCandidates
        }
        // Authentic defaults representing nearby curated places
        return [
            CandidatePlace(
                name: "Golden Gate Park",
                category: .publicPark,
                latitude: 37.7694,
                longitude: -122.4862,
                distanceMeters: 1200,
                address: "San Francisco, CA"
            ),
            CandidatePlace(
                name: "Palace of Fine Arts",
                category: .worldHeritage,
                latitude: 37.8029,
                longitude: -122.4484,
                distanceMeters: 3200,
                address: "Marina District"
            ),
            CandidatePlace(
                name: "Ferry Building Marketplace",
                category: .foodMarket,
                latitude: 37.7955,
                longitude: -122.3937,
                distanceMeters: 4500,
                address: "Embarcadero"
            )
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // 1. Roamly Identity & Contextual Greeting Header
                    headerIdentitySection
                    
                    // 2. Large Editorial Heading
                    editorialTitleSection
                    
                    // 3. Spatial Map Experience (Large, rounded, integrated)
                    spatialMapSection
                    
                    // 4. Editorial Destination Card (Restrained, calm, one clear action)
                    editorialDestinationCard
                    
                    // 5. Places Relevant to the User (Compact horizontal modules)
                    placesForYouSection
                    
                    // 6. Current Trip / Day Timeline & Status
                    currentTripTimelineSection
                    
                    // 7. Base Camp & Outbox Telemetry Row
                    baseCampAndOutboxRow
                    
                    // 8. Developer Expedition Lab & Simulator Suite (Quietly collapsible)
                    developerLabDrawer
                    
                    // Clearance for minimal bottom navigation dock
                    Spacer()
                        .frame(height: 70)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.parchment)
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingHomeSetup) {
                HomeSetupView()
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCaptureView()
            }
            .sheet(isPresented: $isShowingDirectConfirmation) {
                VisitConfirmationSheet(
                    capturedImage: appState.pendingCapturedImage
                )
            }
            .sheet(isPresented: $isShowingCloudSyncSheet) {
                CloudSyncSettingsView()
            }
            .alert("Authenticity Check", isPresented: Binding(
                get: { antiCheatAlert != nil },
                set: { if !$0 { antiCheatAlert = nil } }
            )) {
                Button("Dismiss") {}
            } message: {
                Text(antiCheatAlert ?? "")
            }
            .onAppear {
                LocationManagerService.shared.requestPermissions()
                MotionActivityService.shared.startMonitoring()
                if let home = primaryHome {
                    LocationManagerService.shared.configureHomeGeofence(
                        coordinate: .init(latitude: home.latitude, longitude: home.longitude),
                        radiusMeters: home.radiusMeters
                    )
                }
                updateMapRegion()
            }
        }
    }
    
    // MARK: - 1. Roamly Identity & Greeting Header
    
    private var headerIdentitySection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("roamly")
                    .font(.system(.subheadline, design: .serif, weight: .medium))
                    .tracking(1.8)
                    .foregroundColor(AppTheme.charcoal)
                
                Text(timeGreeting)
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Roamly, \(timeGreeting)")
            
            Spacer()
            
            Button(action: { isShowingSettings = true }) {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(AppTheme.charcoal)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.parchmentSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.subtleBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens app appearance, notifications, and profile")
        }
    }
    
    // MARK: - 2. Large Editorial Heading
    
    private var editorialTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Let's go\nsomewhere.")
                .font(AppTypography.editorialTitle(size: 40, weight: .regular))
                .foregroundColor(AppTheme.charcoal)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Your places, plans and spontaneous moments — beautifully brought together.")
                .font(AppTypography.editorialSubhead(size: 15))
                .foregroundColor(AppTheme.mutedWarmGray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - 3. Spatial Map Experience (Large, rounded, calm)
    
    private var spatialMapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Map(position: $mapCameraPosition) {
                    // Home Base Camp Marker
                    if let home = primaryHome {
                        Annotation("Base Camp", coordinate: CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.charcoal.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Circle()
                                    .fill(AppTheme.charcoal)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "house.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Current Destination Pin
                    Annotation(currentDestinationName, coordinate: CLLocationCoordinate2D(latitude: appState.candidateLatitude, longitude: appState.candidateLongitude)) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.terracotta.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(AppTheme.terracotta)
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: currentDestinationCategory.systemIcon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Nearby places markers
                    ForEach(placesForYou) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            Circle()
                                .fill(selectedNearbyPlace?.id == place.id ? AppTheme.terracotta : AppTheme.charcoal.opacity(0.6))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                .onTapGesture {
                                    if reduceMotion {
                                        selectedNearbyPlace = place
                                        appState.candidatePlaceName = place.name
                                        appState.candidateCategory = place.category
                                        appState.candidateLatitude = place.latitude
                                        appState.candidateLongitude = place.longitude
                                        updateMapRegion()
                                    } else {
                                        withAnimation {
                                            selectedNearbyPlace = place
                                            appState.candidatePlaceName = place.name
                                            appState.candidateCategory = place.category
                                            appState.candidateLatitude = place.latitude
                                            appState.candidateLongitude = place.longitude
                                            updateMapRegion()
                                        }
                                    }
                                }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Spatial map showing Base Camp and destination \(currentDestinationName)")
                
                // Spatial Expand Button (Opens dedicated Explore Map tab)
                Button(action: {
                    appState.selectedTab = 1
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Spatial View")
                            .font(AppTypography.uiTag(size: 9, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(AppTheme.parchmentSurface.opacity(0.92))
                    .foregroundColor(AppTheme.charcoal)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.subtleBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open full Spatial Map view")
                .padding(10)
            }
        }
    }
    
    // MARK: - 4. Editorial Destination Card
    
    private var editorialDestinationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(destinationSectionTitle.uppercased())
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.mutedWarmGray)
                
                Spacer()
                
                if appState.currentState != .atHome {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppTheme.terracotta)
                            .frame(width: 6, height: 6)
                        Text(String(format: "%.1f km traversed", appState.currentTripDistanceKm))
                            .font(AppTypography.uiTag(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentDestinationName)
                    .font(AppTypography.destinationTitle(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(destinationContextualSubtitle)
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            // Contextual natural messaging (Invisible intelligence, no AI hype)
            Text(destinationNaturalMessage)
                .font(AppTypography.editorialSubhead(size: 14))
                .foregroundColor(AppTheme.charcoal.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
            
            Divider()
                .background(AppTheme.subtleBorder)
            
            // Single clear primary action
            HStack {
                if appState.currentState == .potentialVisit || appState.currentState == .awaitingConfirmation {
                    Button(action: { isShowingCamera = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Record Destination Proof")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(RoamlyPrimaryButtonStyle(height: 48, backgroundColor: AppTheme.terracotta))
                    .accessibilityLabel("Record Destination Proof with camera")
                } else if appState.currentState == .traveling || appState.currentState == .leftHome {
                    Button(action: { isShowingCamera = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.north.line.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Record Current Place")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(RoamlyPrimaryButtonStyle(height: 48, backgroundColor: AppTheme.charcoal))
                    .accessibilityLabel("Record Current Place with camera")
                } else {
                    Button(action: { appState.selectedTab = 1 }) {
                        HStack(spacing: 6) {
                            Text("Explore Nearby")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(RoamlySecondaryButtonStyle(tintColor: AppTheme.charcoal))
                    .accessibilityLabel("Explore Nearby places in spatial map")
                }
            }
        }
        .padding(18)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private var destinationSectionTitle: String {
        switch appState.currentState {
        case .atHome: return "BASE CAMP"
        case .leftHome, .traveling: return "ACTIVE JOURNEY"
        case .potentialVisit, .awaitingConfirmation: return "DESTINATION REACHED"
        case .photoCapture: return "CAPTURING PROOF"
        case .validating, .confirmed, .scoring: return "JOURNEY CONFIRMED"
        }
    }
    
    private var destinationContextualSubtitle: String {
        switch appState.currentState {
        case .atHome:
            let placeCount = visits.count
            return "\(primaryHome?.name ?? "San Francisco") · \(placeCount) \(placeCount == 1 ? "place" : "places") recorded"
        case .leftHome, .traveling:
            return "En route via \(MotionActivityService.shared.currentActivityType) · \(String(format: "%.1f", appState.currentTripDistanceKm)) km"
        case .potentialVisit, .awaitingConfirmation:
            return "\(currentDestinationCategory.displayName) · Verified sensor presence"
        default:
            return "Expedition in progress"
        }
    }
    
    private var destinationNaturalMessage: String {
        switch appState.currentState {
        case .atHome:
            return "Base Camp is set. Roamly will quietly monitor departures when you embark on your next trip."
        case .leftHome, .traveling:
            return "You're traveling outside base camp. When you pause at an interesting place, Roamly is ready to preserve it."
        case .potentialVisit, .awaitingConfirmation:
            return "You've arrived near \(currentDestinationName). Capture a photo proof to record this memory in your journal."
        default:
            return "Your journey details are safely being bound with cryptographic telemetry."
        }
    }
    
    // MARK: - 5. Places Relevant to the User ("PLACES FOR YOU")
    
    private var placesForYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(
                title: "Places for You",
                actionTitle: "See all",
                action: { appState.selectedTab = 1 }
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(placesForYou) { place in
                        Button(action: {
                            if reduceMotion {
                                selectedNearbyPlace = place
                                appState.candidatePlaceName = place.name
                                appState.candidateCategory = place.category
                                appState.candidateLatitude = place.latitude
                                appState.candidateLongitude = place.longitude
                                updateMapRegion()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedNearbyPlace = place
                                    appState.candidatePlaceName = place.name
                                    appState.candidateCategory = place.category
                                    appState.candidateLatitude = place.latitude
                                    appState.candidateLongitude = place.longitude
                                    updateMapRegion()
                                }
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: place.category.systemIcon)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.charcoal)
                                    Spacer()
                                    if place.distanceMeters > 0 {
                                        Text(String(format: "%.1f km", place.distanceMeters / 1000.0))
                                            .font(AppTypography.uiTag(size: 9, weight: .regular))
                                            .foregroundColor(AppTheme.mutedWarmGray)
                                    }
                                }
                                
                                Text(place.name)
                                    .font(AppTypography.destinationTitle(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.charcoal)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text(place.category.displayName)
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(AppTheme.mutedWarmGray)
                            }
                            .padding(14)
                            .frame(minWidth: 160, maxWidth: 200, alignment: .leading)
                            .background(selectedNearbyPlace?.id == place.id ? AppTheme.parchmentSurface : AppTheme.parchmentSurface.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(selectedNearbyPlace?.id == place.id ? AppTheme.terracotta : AppTheme.subtleBorder, lineWidth: selectedNearbyPlace?.id == place.id ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(place.name), \(place.category.displayName), \(String(format: "%.1f kilometers away", place.distanceMeters / 1000.0))")
                        .accessibilityHint("Selects \(place.name) on the spatial map")
                    }
                }
            }
        }
    }
    
    // MARK: - 6. Current Trip / Day Timeline Section
    
    private var currentTripTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Current Journey")
            
            // Stationary dwell radar banner if active
            if DestinationDetectorService.shared.isDwellTimerActive {
                let detector = DestinationDetectorService.shared
                let progress = min(1.0, Double(detector.dwellElapsedSeconds) / Double(max(1, detector.dwellRequiredSeconds)))
                
                HStack(spacing: 12) {
                    Circle()
                        .stroke(AppTheme.subtleBorder, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(AppTheme.terracotta, lineWidth: 2)
                                .rotationEffect(.degrees(-90))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dwelling near destination")
                            .font(.system(.subheadline, design: .default, weight: .medium))
                            .foregroundColor(AppTheme.charcoal)
                        Text("\(detector.dwellElapsedSeconds)s of \(detector.dwellRequiredSeconds)s required")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                    
                    Spacer()
                    
                    Button("Confirm") {
                        if let coord = detector.dwellStartCoordinate ?? LocationManagerService.shared.currentLocation?.coordinate {
                            detector.completeDwell(at: coord)
                        } else {
                            detector.completeDwell(at: CLLocationCoordinate2D(latitude: 37.8029, longitude: -122.4484))
                        }
                    }
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .foregroundColor(AppTheme.terracotta)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .background(AppTheme.terracottaSubtle)
                    .clipShape(Capsule())
                }
                .padding(14)
                .background(AppTheme.parchmentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Dwelling near destination. \(detector.dwellElapsedSeconds) seconds of \(detector.dwellRequiredSeconds) seconds required.")
            } else if let latestVisit = visits.sorted(by: { $0.capturedAt > $1.capturedAt }).first {
                // Latest logged trip row (Editorial timeline style)
                HStack(spacing: 14) {
                    VStack(alignment: .center, spacing: 4) {
                        Text(latestVisit.capturedAt.formatted(.dateTime.hour().minute()))
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(AppTheme.mutedWarmGray)
                        Circle()
                            .fill(AppTheme.terracotta)
                            .frame(width: 6, height: 6)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(latestVisit.placeName)
                            .font(AppTypography.destinationTitle(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.charcoal)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text(latestVisit.travelMode.displayName)
                                .font(.system(.caption, design: .default))
                                .foregroundColor(AppTheme.mutedWarmGray)
                            Text("·")
                                .font(.caption2)
                                .foregroundColor(AppTheme.mutedWarmGray)
                            Text(String(format: "%.1f km", latestVisit.distanceKm))
                                .font(.system(.caption, design: .default))
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                    }
                    
                    Spacer()
                    
                    ScoreBadgeView(score: latestVisit.calculatedScore)
                }
                .padding(14)
                .background(AppTheme.parchmentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Latest expedition: \(latestVisit.placeName), \(latestVisit.travelMode.displayName), \(String(format: "%.1f km", latestVisit.distanceKm)), \(latestVisit.calculatedScore) points")
            } else {
                Text("Your itinerary is ready to record as you step outside.")
                    .font(AppTypography.editorialSubhead(size: 14))
                    .foregroundColor(AppTheme.mutedWarmGray)
                    .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - 7. Base Camp & Outbox Telemetry Row
    
    private var baseCampAndOutboxRow: some View {
        HStack(spacing: 12) {
            Button(action: { isShowingHomeSetup = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "house")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.charcoal)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Base Camp")
                            .font(.system(.caption, design: .default, weight: .semibold))
                            .foregroundColor(AppTheme.charcoal)
                        Text(primaryHome?.name ?? "Set Up Base")
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(minHeight: 52)
                .background(AppTheme.parchmentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Base Camp: \(primaryHome?.name ?? "Set Up Base")")
            .accessibilityHint("Double tap to configure Base Camp location and geofence")
            
            Button(action: { isShowingCloudSyncSheet = true }) {
                HStack(spacing: 10) {
                    Image(systemName: SyncEngine.shared.isOnline ? "cloud" : "cloud.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SyncEngine.shared.isOnline ? AppTheme.charcoal : AppTheme.terracotta)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cloud Journal")
                            .font(.system(.caption, design: .default, weight: .semibold))
                            .foregroundColor(AppTheme.charcoal)
                        Text(SyncEngine.shared.isOnline ? "Synchronized" : "Offline")
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(minHeight: 52)
                .background(AppTheme.parchmentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cloud Journal Sync status: \(SyncEngine.shared.isOnline ? "Synchronized" : "Offline")")
            .accessibilityHint("Double tap to inspect PostGIS cloud sync queue")
        }
    }
    
    // MARK: - 8. Developer Expedition Lab & Simulator Suite
    
    private var developerLabDrawer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                if reduceMotion {
                    isLabExpanded.toggle()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isLabExpanded.toggle()
                    }
                }
            }) {
                HStack {
                    Text("EXPEDITION LAB & SIMULATOR")
                        .font(AppTypography.uiTag(size: 9, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(AppTheme.mutedWarmGray)
                    Spacer()
                    Image(systemName: isLabExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                .frame(minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expedition Lab and Simulator, \(isLabExpanded ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to toggle simulation controls")
            
            if isLabExpanded {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: {
                            LocationManagerService.shared.simulateDeparture(distanceMeters: 1800)
                            MotionActivityService.shared.simulateMotion(type: .walking)
                            updateMapRegion()
                        }) {
                            Text("Simulate Departure")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(AppTheme.parchment)
                                .foregroundColor(AppTheme.charcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AppTheme.subtleBorder, lineWidth: 0.75))
                        }
                        
                        Button(action: {
                            appState.resetTrip()
                            MotionActivityService.shared.simulateMotion(type: .stationary)
                            updateMapRegion()
                        }) {
                            Text("Reset to Base")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(AppTheme.parchment)
                                .foregroundColor(AppTheme.charcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AppTheme.subtleBorder, lineWidth: 0.75))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: seedSampleLogbook) {
                            Text("Seed 5 Journeys")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(AppTheme.parchment)
                                .foregroundColor(AppTheme.charcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AppTheme.subtleBorder, lineWidth: 0.75))
                        }
                        
                        Button(action: testBadgeCelebration) {
                            Text("Test Milestone")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(AppTheme.parchment)
                                .foregroundColor(AppTheme.terracotta)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AppTheme.subtleBorder, lineWidth: 0.75))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(AppTheme.parchmentSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Actions & Helpers
    
    private func updateMapRegion() {
        let center = currentCenterCoordinate
        if reduceMotion {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                mapCameraPosition = .region(MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                ))
            }
        }
    }
    
    private func testBadgeCelebration() {
        let testBadge = AchievementBadge(
            id: "test_celebration_\(Int.random(in: 1000...9999))",
            title: "Trail Pioneer",
            subtitle: "Completed an inaugural 5km eco-friendly journey",
            systemIcon: "figure.walk.motion",
            color: AppTheme.terracotta,
            currentProgress: 1,
            requiredProgress: 1,
            pointsReward: 150
        )
        AchievementCelebrationManager.shared.triggerCelebration(badge: testBadge, force: true)
    }
    
    private func seedSampleLogbook() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let userCurrency = UserSettingsService.shared.currencyCode
        
        let sampleData: [(name: String, cat: DestinationCategory, mode: TravelMode, dist: Double, date: Date, spend: Double, curr: String, score: Int)] = [
            ("Golden Gate National Park", .nationalPark, .cycling, 6.4, today, 0.0, userCurrency, 480),
            ("Palace of Fine Arts", .worldHeritage, .walking, 3.2, today, 14.50, userCurrency, 520),
            ("de Young Museum", .museum, .walking, 2.1, yesterday, 28.00, userCurrency, 390),
            ("Ferry Building Marketplace", .foodMarket, .bus, 5.0, twoDaysAgo, 18.20, userCurrency, 310),
            ("Muir Woods Redwoods", .nationalPark, .train, 18.5, threeDaysAgo, 15.00, userCurrency, 620)
        ]
        
        for item in sampleData {
            let id = UUID()
            let hash = "1010101010101010\(abs(item.name.hashValue))"
            let entity = VisitEntity(
                id: id,
                placeName: item.name,
                categoryRaw: item.cat.rawValue,
                latitude: 37.7694 + Double.random(in: -0.05...0.05),
                longitude: -122.4862 + Double.random(in: -0.05...0.05),
                capturedAt: item.date,
                travelModeRaw: item.mode.rawValue,
                spendingAmount: item.spend,
                spendingCurrency: item.curr,
                localPhotoPath: nil,
                photoHash: hash,
                calculatedScore: item.score,
                distanceKm: item.dist,
                isVerified: true,
                isSynced: false
            )
            modelContext.insert(entity)
        }
        try? modelContext.save()
        
        let descriptor = FetchDescriptor<VisitEntity>()
        if let allVisits = try? modelContext.fetch(descriptor) {
            AchievementCelebrationManager.shared.evaluateAndCelebrate(visits: allVisits)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
