import SwiftUI
import CoreLocation

struct OnboardingLocationPermissionView: View {
    let onContinue: () -> Void
    
    @State private var locationManager = LocationManagerService.shared
    
    private var isAuthorized: Bool {
        locationManager.authorizationStatus == .authorizedAlways ||
        locationManager.authorizationStatus == .authorizedWhenInUse
    }
    
    private var isDenied: Bool {
        locationManager.authorizationStatus == .denied ||
        locationManager.authorizationStatus == .restricted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(isAuthorized ? AppTheme.baseGreenLight : AppTheme.transitBlueLight)
                            .frame(width: 92, height: 92)
                        
                        Image(systemName: isAuthorized ? "checkmark.circle.fill" : "location.circle.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(isAuthorized ? AppTheme.baseGreen : AppTheme.transitBlue)
                    }
                    .padding(.top, 24)
                    
                    // Title & Description
                    VStack(spacing: 8) {
                        Text("Location Permission")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Roamly uses your location to detect when you leave home and identify places you visit.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Status Card
                    permissionStatusCard
                    
                    // Value Pillars
                    VStack(spacing: 12) {
                        reasonRow(
                            icon: "house.fill",
                            color: AppTheme.baseGreen,
                            title: "Hardware Geofencing",
                            description: "Low-power boundary monitoring that triggers only when leaving base."
                        )
                        
                        reasonRow(
                            icon: "sparkles",
                            color: AppTheme.amberAccent,
                            title: "Place Identification",
                            description: "Identifies points of interest when you dwell at a new destination."
                        )
                        
                        reasonRow(
                            icon: "battery.100",
                            color: AppTheme.transitBlue,
                            title: "Battery Optimized",
                            description: "Sleeps when stationary so your battery life is preserved."
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // Bottom Action Bar
            VStack(spacing: 12) {
                Divider()
                
                if isAuthorized {
                    Button(action: onContinue) {
                        Text("Continue")
                    }
                    .buttonStyle(RoamlyPrimaryButtonStyle())
                } else if isDenied {
                    Button(action: openSystemSettings) {
                        Text("Open iPhone Settings")
                    }
                    .buttonStyle(RoamlyPrimaryButtonStyle(backgroundColor: AppTheme.amberAccent))
                    
                    Button(action: onContinue) {
                        Text("Continue Without Location")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: requestPermission) {
                        Text("Allow Location Access")
                    }
                    .buttonStyle(RoamlyPrimaryButtonStyle())
                    
                    Button(action: onContinue) {
                        Text("Skip For Now")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(AppTheme.cardBackground)
        }
    }
    
    // MARK: - Subviews
    
    private var permissionStatusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: isAuthorized ? "lock.open.shield.fill" : "shield.slash.fill")
                .font(.title2)
                .foregroundColor(isAuthorized ? AppTheme.baseGreen : AppTheme.amberAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isAuthorized ? "Location Access Enabled" : "Access Not Yet Granted")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(isAuthorized ? "Ready for background travel detection" : "Departure alerts require location permissions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusPill(
                title: isAuthorized ? "Active" : "Required",
                icon: isAuthorized ? "checkmark" : "exclamationmark",
                color: isAuthorized ? AppTheme.baseGreen : AppTheme.amberAccent
            )
        }
        .roamlyCard(padding: 14)
    }
    
    private func reasonRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .roamlyCard(padding: 12, cornerRadius: 14)
    }
    
    // MARK: - Actions
    
    private func requestPermission() {
        locationManager.requestPermissions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.isAuthorized {
                self.onContinue()
            }
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
