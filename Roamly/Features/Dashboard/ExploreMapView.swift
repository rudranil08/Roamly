import SwiftUI
import MapKit
import SwiftData

struct ExploreMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var visits: [VisitEntity]
    @Query private var homes: [HomeEntity]
    
    @State private var selectedCategoryFilter: String = "ALL"
    @State private var selectedPlace: CandidatePlace? = nil
    @State private var selectedVisit: VisitEntity? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isShowingConfirmation: Bool = false
    
    private let categories = ["ALL", "Parks", "Culture", "Dining", "Landmarks"]
    
    private var baseHome: HomeEntity? {
        homes.first
    }
    
    private var currentCenter: CLLocationCoordinate2D {
        if let loc = LocationManagerService.shared.currentLocation?.coordinate {
            return loc
        }
        if let home = baseHome {
            return CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
        }
        return CLLocationCoordinate2D(latitude: appState.candidateLatitude, longitude: appState.candidateLongitude)
    }
    
    private var displayCandidates: [CandidatePlace] {
        let candidates = appState.nearbyCandidates
        if candidates.isEmpty {
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
                    address: "3301 Lyon St, San Francisco"
                ),
                CandidatePlace(
                    name: "Ferry Building Marketplace",
                    category: .foodMarket,
                    latitude: 37.7955,
                    longitude: -122.3937,
                    distanceMeters: 4500,
                    address: "1 Ferry Building, San Francisco"
                ),
                CandidatePlace(
                    name: "de Young Museum",
                    category: .museum,
                    latitude: 37.7715,
                    longitude: -122.4687,
                    distanceMeters: 1800,
                    address: "50 Hagiwara Tea Garden Dr"
                )
            ]
        }
        
        if selectedCategoryFilter == "ALL" {
            return candidates
        }
        return candidates.filter { candidate in
            switch selectedCategoryFilter {
            case "Parks":
                return candidate.category == .publicPark || candidate.category == .nationalPark || candidate.category == .botanicalGarden
            case "Culture":
                return candidate.category == .museum || candidate.category == .worldHeritage || candidate.category == .university
            case "Dining":
                return candidate.category == .foodMarket || candidate.category == .commercial
            case "Landmarks":
                return candidate.category == .worldHeritage || candidate.category == .museum
            default:
                return true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Large Spatial Map
                Map(position: $cameraPosition) {
                    // Home Base geofence marker
                    if let home = baseHome {
                        Annotation("Base Camp", coordinate: CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.charcoal.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .fill(AppTheme.charcoal)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "house.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Authentic Candidate Places Markers
                    ForEach(displayCandidates) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            Button(action: {
                                if reduceMotion {
                                    selectedPlace = place
                                    cameraPosition = .region(MKCoordinateRegion(
                                        center: place.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    ))
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedPlace = place
                                        cameraPosition = .region(MKCoordinateRegion(
                                            center: place.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                        ))
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedPlace?.id == place.id ? AppTheme.terracotta : AppTheme.parchmentSurface)
                                        .frame(width: selectedPlace?.id == place.id ? 38 : 32, height: selectedPlace?.id == place.id ? 38 : 32)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedPlace?.id == place.id ? Color.white : AppTheme.subtleBorder, lineWidth: 2)
                                        )
                                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: place.category.systemIcon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedPlace?.id == place.id ? .white : AppTheme.charcoal)
                                }
                                .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(place.name), \(place.category.displayName)")
                            .accessibilityHint("Selects this destination on the map")
                        }
                    }
                    
                    // Past Visited Places (subtle dots)
                    ForEach(visits) { visit in
                        Annotation(visit.placeName, coordinate: CLLocationCoordinate2D(latitude: visit.latitude, longitude: visit.longitude)) {
                            Circle()
                                .fill(AppTheme.terracotta.opacity(0.6))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedVisit = visit
                                }
                                .accessibilityLabel("Past journey: \(visit.placeName)")
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .ignoresSafeArea(edges: .top)
                
                // Top Editorial Filter Pill Bar
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("EXPLORE")
                                .font(AppTypography.uiTag(size: 10, weight: .bold))
                                .tracking(1.4)
                                .foregroundColor(AppTheme.mutedWarmGray)
                            Text("Spatial Landscape")
                                .font(AppTypography.destinationTitle(size: 20, weight: .regular))
                                .foregroundColor(AppTheme.charcoal)
                        }
                        
                        Spacer()
                        
                        // Recenter button (accessible 44x44pt target)
                        Button(action: recenterOnUser) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppTheme.subtleBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Recenter map on current location")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.parchment.opacity(0.95), AppTheme.parchment.opacity(0.7), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Horizontal category filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    if reduceMotion {
                                        selectedCategoryFilter = category
                                    } else {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            selectedCategoryFilter = category
                                        }
                                    }
                                }) {
                                    Text(category)
                                        .font(.system(.footnote, design: .default, weight: selectedCategoryFilter == category ? .semibold : .regular))
                                        .padding(.horizontal, 14)
                                        .frame(minHeight: 44)
                                        .background(selectedCategoryFilter == category ? AppTheme.charcoal : AppTheme.parchmentSurface)
                                        .foregroundColor(selectedCategoryFilter == category ? AppTheme.parchmentSurface : AppTheme.charcoal)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.subtleBorder, lineWidth: selectedCategoryFilter == category ? 0 : 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Filter: \(category)")
                                .accessibilityAddTraits(selectedCategoryFilter == category ? [.isButton, .isSelected] : [.isButton])
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                
                // Bottom Selected Place Card (Editorial Presentation)
                VStack(spacing: 12) {
                    if let place = selectedPlace {
                        placeEditorialCard(place)
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer()
                        .frame(height: 75) // Clearance for bottom navigation dock
                }
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedVisit) { visit in
                VisitDetailView(visit: visit)
            }
            .sheet(isPresented: $isShowingConfirmation) {
                VisitConfirmationSheet(
                    capturedImage: nil,
                    onVisitSaved: {
                        selectedPlace = nil
                    }
                )
            }
            .onAppear {
                recenterOnUser()
                if let first = displayCandidates.first {
                    selectedPlace = first
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func placeEditorialCard(_ place: CandidatePlace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.category.displayName.uppercased())
                        .font(AppTypography.uiTag(size: 9, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(AppTheme.mutedWarmGray)
                    
                    Text(place.name)
                        .font(AppTypography.destinationTitle(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let address = place.address {
                        Text(address)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if reduceMotion {
                        selectedPlace = nil
                    } else {
                        withAnimation {
                            selectedPlace = nil
                        }
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.parchment)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close destination details")
            }
            
            Divider()
                .background(AppTheme.subtleBorder)
            
            HStack(spacing: 12) {
                if place.distanceMeters > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.mutedWarmGray)
                            .accessibilityHidden(true)
                        Text(String(format: "%.1f km away", place.distanceMeters / 1000.0))
                            .font(.system(.footnote, design: .default, weight: .medium))
                            .foregroundColor(AppTheme.charcoal)
                    }
                    .accessibilityLabel("\(String(format: "%.1f kilometers away", place.distanceMeters / 1000.0))")
                }
                
                Spacer()
                
                Button(action: {
                    appState.candidatePlaceName = place.name
                    appState.candidateCategory = place.category
                    appState.candidateLatitude = place.latitude
                    appState.candidateLongitude = place.longitude
                    isShowingConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .accessibilityHidden(true)
                        Text("Record Place")
                            .font(.system(.callout, design: .default, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(AppTheme.terracotta)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Record \(place.name)")
                .accessibilityHint("Opens visit confirmation sheet")
            }
        }
        .padding(16)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private func recenterOnUser() {
        let center = currentCenter
        if reduceMotion {
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            ))
        } else {
            withAnimation(.easeInOut(duration: 0.6)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                ))
            }
        }
    }
}
