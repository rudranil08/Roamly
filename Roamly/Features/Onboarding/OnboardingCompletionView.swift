import SwiftUI
import SwiftData

struct OnboardingCompletionView: View {
    @Query private var homes: [HomeEntity]
    let onFinish: () -> Void
    @State private var isPulsing: Bool = false
    
    private var homeBaseName: String {
        homes.first?.name ?? "Home Base"
    }
    
    private var currentCurrency: CurrencyOption {
        UserSettingsService.shared.currentCurrency
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Celebration Icon with glowing pulsing aura
            ZStack {
                Circle()
                    .fill(AppTheme.baseGreen.opacity(isPulsing ? 0.22 : 0.10))
                    .frame(width: 124, height: 124)
                    .scaleEffect(isPulsing ? 1.08 : 0.94)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                
                Circle()
                    .fill(AppTheme.baseGreenLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(AppTheme.baseGreen)
            }
            .padding(.bottom, 24)
            
            // Title & Subtitle
            VStack(spacing: 8) {
                Text("You're Ready!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Your Roamly journey starts here.")
                    .font(.title3)
                    .foregroundColor(AppTheme.baseGreen)
            }
            .padding(.bottom, 28)
            
            // Setup Summary Card
            VStack(spacing: 12) {
                summaryRow(
                    icon: "house.fill",
                    label: "Home Base",
                    value: homeBaseName
                )
                
                Divider()
                
                summaryRow(
                    icon: "banknote.fill",
                    label: "Spending Currency",
                    value: "\(currentCurrency.name) (\(currentCurrency.code) \(currentCurrency.symbol))"
                )
                
                Divider()
                
                summaryRow(
                    icon: "lock.shield.fill",
                    label: "Privacy",
                    value: "Private on-device geofencing"
                )
            }
            .roamlyCard(padding: 16)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Primary Action
            Button(action: onFinish) {
                Text("Start Exploring")
            }
            .buttonStyle(RoamlyPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            isPulsing = true
        }
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.baseGreenLight)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.baseGreen)
            }
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
