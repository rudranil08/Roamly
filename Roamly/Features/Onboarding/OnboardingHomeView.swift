import SwiftUI
import MapKit
import SwiftData

struct OnboardingHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var homes: [HomeEntity]
    
    let onContinue: () -> Void
    
    @State private var homeName: String = "Home Base"
    @State private var radiusMeters: Double = 150.0
    @State private var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var approximateAddress: String = "Detecting address..."
    @State private var isGeocoding: Bool = false
    @State private var isShowingManualSetup: Bool = false
    @State private var hasLocationFix: Bool = false
    
    private let locationManager = LocationManagerService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Set Your Home")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Roamly uses your home as the starting point for your travel journeys.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // Location Detection Status / Suggestion Card
                    if hasLocationFix {
                        suggestedLocationCard
                    } else {
                        requestLocationCard
                    }
                    
                    // Geofence Radius Slider Card
                    radiusCard
                    
                    // Privacy Guarantee Box
                    privacyNoticeCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // Bottom Action Bar
            VStack(spacing: 12) {
                Divider()
                
                Button(action: confirmAndContinue) {
                    Text("Confirm Home Base")
                }
                .buttonStyle(RoamlyPrimaryButtonStyle())
                
                Button(action: { isShowingManualSetup = true }) {
                    Text("Change Location Manually")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.transitBlue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(AppTheme.cardBackground)
        }
        .sheet(isPresented: $isShowingManualSetup) {
            HomeSetupView()
                .onDisappear {
                    refreshFromSavedHome()
                }
        }
        .onAppear {
            initializeLocation()
        }
    }
    
    // MARK: - Subviews
    
    private var suggestedLocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("SUGGESTED HOME BASE", systemImage: "mappin.circle.fill")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.baseGreen)
                Spacer()
                if isGeocoding {
                    ProgressView().controlSize(.small)
                }
            }
            
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.baseGreenLight)
                        .frame(width: 48, height: 48)
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.baseGreen)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    TextField("Base Name", text: $homeName)
                        .font(.headline)
                    
                    Text(approximateAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Text("Suggested automatically from your current GPS position.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .roamlyCard()
    }
    
    private var requestLocationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("LOCATION PERMISSION", systemImage: "location.circle.fill")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.amberAccent)
                Spacer()
            }
            
            Text("To automatically suggest your home base, Roamly needs permission to access your location.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: requestLocationAccess) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text("Use My Current Location")
                        .font(.subheadline.bold())
                }
            }
            .buttonStyle(RoamlyPrimaryButtonStyle(height: 44))
        }
        .roamlyCard()
    }
    
    private var radiusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("GEOFENCE RADIUS")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(radiusMeters))m")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.baseGreen)
            }
            
            Slider(value: $radiusMeters, in: 150...1000, step: 25)
                .tint(AppTheme.baseGreen)
            
            Text("Journeys start automatically once you move outside this boundary.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .roamlyCard()
    }
    
    private var privacyNoticeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title3)
                .foregroundColor(AppTheme.baseGreen)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Privacy Protected")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text("Your exact home coordinates are stored privately on this device for hardware geofencing only. They are never shared publicly or displayed on leaderboards.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(AppTheme.baseGreenLight)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.inputCornerRadius, style: .continuous))
    }
    
    // MARK: - Actions
    
    private func initializeLocation() {
        if let existing = homes.first {
            homeName = existing.name
            radiusMeters = existing.radiusMeters
            selectedCoordinate = CLLocationCoordinate2D(latitude: existing.latitude, longitude: existing.longitude)
            hasLocationFix = true
            reverseGeocode(coordinate: selectedCoordinate)
            return
        }
        
        if let current = locationManager.currentLocation {
            selectedCoordinate = current.coordinate
            hasLocationFix = true
            reverseGeocode(coordinate: selectedCoordinate)
        } else {
            locationManager.requestPermissions()
        }
    }
    
    private func requestLocationAccess() {
        locationManager.requestPermissions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let current = self.locationManager.currentLocation {
                self.selectedCoordinate = current.coordinate
                self.hasLocationFix = true
                self.reverseGeocode(coordinate: current.coordinate)
            }
        }
    }
    
    private func refreshFromSavedHome() {
        if let existing = homes.first {
            homeName = existing.name
            radiusMeters = existing.radiusMeters
            selectedCoordinate = CLLocationCoordinate2D(latitude: existing.latitude, longitude: existing.longitude)
            hasLocationFix = true
            reverseGeocode(coordinate: selectedCoordinate)
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            DispatchQueue.main.async {
                self.isGeocoding = false
                if let placemark = placemarks?.first {
                    let street = placemark.thoroughfare ?? ""
                    let city = placemark.locality ?? placemark.subAdministrativeArea ?? ""
                    let area = [street, city].filter { !$0.isEmpty }.joined(separator: ", ")
                    self.approximateAddress = area.isEmpty ? "Current Location" : area
                } else {
                    self.approximateAddress = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                }
            }
        }
    }
    
    private func confirmAndContinue() {
        let descriptor = FetchDescriptor<HomeEntity>()
        if let existing = try? modelContext.fetch(descriptor) {
            for item in existing {
                modelContext.delete(item)
            }
        }
        
        let newHome = HomeEntity(
            name: homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Home Base" : homeName,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            radiusMeters: radiusMeters
        )
        modelContext.insert(newHome)
        try? modelContext.save()
        
        LocationManagerService.shared.configureHomeGeofence(
            coordinate: selectedCoordinate,
            radiusMeters: radiusMeters
        )
        
        onContinue()
    }
}
