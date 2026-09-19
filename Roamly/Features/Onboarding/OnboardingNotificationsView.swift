import SwiftUI
import UserNotifications

struct OnboardingNotificationsView: View {
    let onContinue: () -> Void
    
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.amberAccentLight)
                            .frame(width: 92, height: 92)
                        
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 46, weight: .medium))
                            .foregroundColor(AppTheme.amberAccent)
                    }
                    .padding(.top, 24)
                    
                    // Title & Description
                    VStack(spacing: 8) {
                        Text("Stay in the Loop")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Roamly notifies you when you arrive at exciting places so you never miss logging a journey.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Notification Highlights
                    VStack(spacing: 12) {
                        notificationItem(
                            icon: "mappin.and.ellipse",
                            color: AppTheme.amberAccent,
                            title: "Destination Dwell Alerts",
                            description: "Get notified when you arrive at a notable venue or landmark so you can log your visit."
                        )
                        
                        notificationItem(
                            icon: "sparkles",
                            color: AppTheme.baseGreen,
                            title: "Score & Streak Updates",
                            description: "Celebrate points earned, eco multipliers, and weekly ranking milestones."
                        )
                    }
                    
                    Text("Notifications are optional and can be managed anytime in iOS Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // Bottom Action Bar
            VStack(spacing: 12) {
                Divider()
                
                Button(action: requestNotificationPermission) {
                    Text("Enable Notifications")
                }
                .buttonStyle(RoamlyPrimaryButtonStyle())
                
                Button(action: onContinue) {
                    Text("Maybe Later")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(AppTheme.cardBackground)
        }
        .onAppear {
            checkCurrentStatus()
        }
    }
    
    private func notificationItem(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)
                
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
    
    private func checkCurrentStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.onContinue()
            }
        }
    }
}
