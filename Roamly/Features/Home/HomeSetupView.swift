import SwiftUI
import MapKit
import SwiftData

struct HomeSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var homes: [HomeEntity]
    
    @State private var homeName: String = "Home Base"
    @State private var radiusMeters: Double = 150.0
    @State private var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var position: MapCameraPosition = .automatic
    @State private var resolvedAddress: String = "Locating address..."
    @State private var isGeocoding: Bool = false
    
    private let locationManager = LocationManagerService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Interactive Map
                mapSection
                    .frame(height: 320)
                
                // Form & Controls
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Home Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BASE NAME")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. Home, Apartment, Basecamp", text: $homeName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Geofence Radius
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("GEOFENCE RADIUS")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(radiusMeters)) meters")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.baseGreen)
                            }
                            
                            Slider(value: $radiusMeters, in: 150...1000, step: 25)
                                .tint(AppTheme.baseGreen)
                            
                            Text("Minimum radius is 150m to guarantee reliable hardware wakeups without battery drain.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Location Details Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COORDINATES & ADDRESS")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resolvedAddress)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(String(format: "Lat: %.5f, Lon: %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isGeocoding {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                        }
                        .padding(14)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Quick Action: Snap to Current Location
                        Button(action: snapToCurrentLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Use Current Location")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.transitBlue.opacity(0.12))
                            .foregroundColor(AppTheme.transitBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
                
                // Save Button
                saveBar
            }
            .background(AppTheme.groupedBackground)
            .navigationTitle("Set Home Base")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadExistingHome)
        }
    }
    
    // MARK: - Subviews
    
    private var mapSection: some View {
        ZStack {
            Map(position: $position) {
                Marker(homeName, coordinate: selectedCoordinate)
                    .tint(AppTheme.baseGreen)
                
                MapCircle(center: selectedCoordinate, radius: radiusMeters)
                    .foregroundStyle(AppTheme.baseGreen.opacity(0.20))
                    .stroke(AppTheme.baseGreen, lineWidth: 2)
            }
            .mapStyle(.standard(elevation: .realistic))
            
            // Map Reticle / Pin Pointer overlay
            VStack {
                Spacer()
                Text("Tap or pan to adjust base coordinate")
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: saveHome) {
                Text("Save Home Geofence")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.baseGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(AppTheme.cardBackground)
    }
    
    // MARK: - Actions
    
    private func loadExistingHome() {
        locationManager.requestPermissions()
        
        if let existing = homes.first {
            homeName = existing.name
            radiusMeters = existing.radiusMeters
            selectedCoordinate = CLLocationCoordinate2D(latitude: existing.latitude, longitude: existing.longitude)
            position = .region(MKCoordinateRegion(
                center: selectedCoordinate,
                latitudinalMeters: max(1000, radiusMeters * 3),
                longitudinalMeters: max(1000, radiusMeters * 3)
            ))
            reverseGeocode(coordinate: selectedCoordinate)
        } else if let userLoc = locationManager.currentLocation?.coordinate {
            selectedCoordinate = userLoc
            position = .region(MKCoordinateRegion(
                center: userLoc,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
            reverseGeocode(coordinate: userLoc)
        } else {
            reverseGeocode(coordinate: selectedCoordinate)
        }
    }
    
    private func snapToCurrentLocation() {
        locationManager.requestPermissions()
        if let userLoc = locationManager.currentLocation?.coordinate {
            selectedCoordinate = userLoc
            position = .region(MKCoordinateRegion(
                center: userLoc,
                latitudinalMeters: max(1000, radiusMeters * 3),
                longitudinalMeters: max(1000, radiusMeters * 3)
            ))
            reverseGeocode(coordinate: userLoc)
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                self.isGeocoding = false
                if let placemark = placemarks?.first {
                    let parts = [placemark.name, placemark.locality, placemark.administrativeArea]
                        .compactMap { $0 }
                    self.resolvedAddress = parts.joined(separator: ", ")
                } else {
                    self.resolvedAddress = "Custom Coordinates"
                }
            }
        }
    }
    
    private func saveHome() {
        if let existing = homes.first {
            existing.name = homeName
            existing.latitude = selectedCoordinate.latitude
            existing.longitude = selectedCoordinate.longitude
            existing.radiusMeters = radiusMeters
            existing.updatedAt = Date()
        } else {
            let newHome = HomeEntity(
                name: homeName,
                latitude: selectedCoordinate.latitude,
                longitude: selectedCoordinate.longitude,
                radiusMeters: radiusMeters
            )
            modelContext.insert(newHome)
        }
        
        try? modelContext.save()
        
        locationManager.configureHomeGeofence(
            coordinate: selectedCoordinate,
            radiusMeters: radiusMeters
        )
        
        dismiss()
    }
}
