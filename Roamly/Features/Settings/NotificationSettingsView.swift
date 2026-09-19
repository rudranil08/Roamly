import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var departureAlertsEnabled: Bool = true
    @State private var milestoneAlertsEnabled: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications")
                        .font(AppTypography.destinationTitle(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                    Text("Receive quiet prompts when leaving Base Camp and celebrating travel milestones.")
                        .font(AppTypography.editorialSubhead(size: 14))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
            }
            
            Section {
                HStack {
                    Text("Permission Status")
                        .font(.system(.body, design: .default))
                        .foregroundColor(AppTheme.charcoal)
                    Spacer()
                    Text(statusDescription)
                        .font(.system(.callout, design: .default))
                        .foregroundColor(statusColor)
                }
                
                if authorizationStatus == .denied {
                    Button(action: openSystemSettings) {
                        HStack {
                            Text("Enable in iOS Settings")
                                .font(.system(.body, design: .default, weight: .medium))
                                .foregroundColor(AppTheme.terracotta)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                    }
                }
            } header: {
                Text("SYSTEM STATUS")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            Section {
                Toggle(isOn: $departureAlertsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Departure Alerts")
                            .font(.system(.body, design: .default))
                            .foregroundColor(AppTheme.charcoal)
                        Text("Notify when departing Base Camp into a new exploration")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                }
                .tint(AppTheme.terracotta)
                
                Toggle(isOn: $milestoneAlertsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Milestone Celebrations")
                            .font(.system(.body, design: .default))
                            .foregroundColor(AppTheme.charcoal)
                        Text("Notify when unlocking new travel medallions")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                }
                .tint(AppTheme.terracotta)
            } header: {
                Text("DISPATCH PREFERENCES")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.parchment)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: checkStatus)
    }
    
    private var statusDescription: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Active"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Configured"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return AppTheme.sageOlive
        case .denied:
            return AppTheme.terracotta
        default:
            return AppTheme.mutedWarmGray
        }
    }
    
    private func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
