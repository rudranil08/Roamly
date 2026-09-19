import SwiftUI

public struct AchievementCelebrationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let badge: AchievementBadge
    let onDismiss: () -> Void
    
    @State private var modalScale: CGFloat = 1.0
    @State private var modalOpacity: Double = 0.0
    
    public init(badge: AchievementBadge, onDismiss: @escaping () -> Void) {
        self.badge = badge
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Calm translucent backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithFeedback()
                }
                .accessibilityLabel("Dismiss celebration backdrop")
                .accessibilityAction {
                    dismissWithFeedback()
                }
            
            // Refined Milestone Card
            VStack(spacing: 0) {
                // Top close button
                HStack {
                    Spacer()
                    Button(action: dismissWithFeedback) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.mutedWarmGray)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(AppTheme.parchment)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close milestone celebration")
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
                
                VStack(spacing: 20) {
                    // Refined Field Mark / Medallion
                    ZStack {
                        Circle()
                            .fill(AppTheme.parchment)
                            .frame(width: 88, height: 88)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.terracotta.opacity(0.3), lineWidth: 1.5)
                            )
                        
                        Circle()
                            .fill(AppTheme.terracottaSubtle)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: badge.systemIcon)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppTheme.terracotta)
                    }
                    .accessibilityHidden(true)
                    .padding(.top, 4)
                    
                    // Milestone Typography
                    VStack(spacing: 6) {
                        Text("MILESTONE REACHED")
                            .font(AppTypography.uiTag(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundColor(AppTheme.terracotta)
                        
                        Text(badge.title)
                            .font(AppTypography.destinationTitle(size: 24, weight: .medium))
                            .foregroundColor(AppTheme.charcoal)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(badge.subtitle)
                            .font(AppTypography.editorialSubhead(size: 14))
                            .foregroundColor(AppTheme.mutedWarmGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Milestone Reached: \(badge.title). \(badge.subtitle)")
                    
                    // Reward Indicator
                    if badge.pointsReward > 0 {
                        HStack(spacing: 4) {
                            Text("+\(badge.pointsReward)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.charcoal)
                            Text("expedition points")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.parchment)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.subtleBorder, lineWidth: 1))
                        .accessibilityLabel("Reward: \(badge.pointsReward) expedition points")
                    }
                    
                    // Single Clear Action Button
                    Button(action: dismissWithFeedback) {
                        Text("Continue Journey")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoamlyPrimaryButtonStyle(height: 48, backgroundColor: AppTheme.charcoal))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 4)
                    .accessibilityLabel("Continue Journey")
                }
            }
            .background(AppTheme.parchmentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
            .padding(.horizontal, 28)
            .scaleEffect(modalScale)
            .opacity(modalOpacity)
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            // Post VoiceOver announcement for screen readers
            UIAccessibility.post(
                notification: .announcement,
                argument: "Milestone reached: \(badge.title). \(badge.subtitle)"
            )
            
            if reduceMotion {
                modalScale = 1.0
                withAnimation(.easeIn(duration: 0.15)) {
                    modalOpacity = 1.0
                }
            } else {
                modalScale = 0.94
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    modalScale = 1.0
                    modalOpacity = 1.0
                }
            }
        }
    }
    
    private func dismissWithFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.12)) {
                modalOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                onDismiss()
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                modalScale = 0.94
                modalOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                onDismiss()
            }
        }
    }
}
