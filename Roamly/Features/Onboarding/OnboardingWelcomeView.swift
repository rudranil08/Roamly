import SwiftUI

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void
    @State private var isPulsing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero Icon with gentle glow aura
            ZStack {
                Circle()
                    .fill(AppTheme.baseGreen.opacity(isPulsing ? 0.20 : 0.10))
                    .frame(width: 114, height: 114)
                    .scaleEffect(isPulsing ? 1.06 : 0.96)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isPulsing)
                
                Circle()
                    .fill(AppTheme.baseGreenLight)
                    .frame(width: 96, height: 96)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundColor(AppTheme.baseGreen)
            }
            .padding(.bottom, 22)
            
            // Title & Core Description
            VStack(spacing: 10) {
                Text("Welcome to Roamly")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Turn your journeys into a personal travel logbook.")
                    .font(.headline)
                    .foregroundColor(AppTheme.baseGreen)
                    .multilineTextAlignment(.center)
                
                Text("Roamly detects meaningful places you visit, lets you confirm them, and turns your adventures into memories and points.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Feature Highlights
            VStack(spacing: 12) {
                featureRow(
                    icon: "house.circle.fill",
                    color: AppTheme.baseGreen,
                    title: "Leave Base",
                    subtitle: "Automatically monitors departures from your home geofence."
                )
                
                featureRow(
                    icon: "sparkles",
                    color: AppTheme.amberAccent,
                    title: "Explore Destinations",
                    subtitle: "Detects notable places, parks, and cultural landmarks."
                )
                
                featureRow(
                    icon: "checkmark.seal.fill",
                    color: AppTheme.transitBlue,
                    title: "Confirm & Score",
                    subtitle: "Log your travel mode and spend to earn sustainability points."
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Primary Action
            Button(action: onGetStarted) {
                Text("Get Started")
            }
            .buttonStyle(RoamlyPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onAppear {
            isPulsing = true
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .roamlyCard(padding: 12, cornerRadius: 14)
    }
}
