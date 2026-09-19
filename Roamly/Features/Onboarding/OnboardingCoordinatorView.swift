import SwiftUI

struct OnboardingCoordinatorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var currentStep: Int = 1
    private let totalSteps: Int = 6
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Progress Indicator
                if currentStep > 1 && currentStep < totalSteps {
                    progressBar
                }
                
                // Step Content
                Group {
                    switch currentStep {
                    case 1:
                        OnboardingWelcomeView(onGetStarted: {
                            advanceStep()
                        })
                    case 2:
                        OnboardingHomeView(onContinue: {
                            advanceStep()
                        })
                    case 3:
                        OnboardingCurrencyView(onContinue: {
                            advanceStep()
                        })
                    case 4:
                        OnboardingLocationPermissionView(onContinue: {
                            advanceStep()
                        })
                    case 5:
                        OnboardingNotificationsView(onContinue: {
                            advanceStep()
                        })
                    case 6:
                        OnboardingCompletionView(onFinish: {
                            finishOnboarding()
                        })
                    default:
                        EmptyView()
                    }
                }
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .background(AppTheme.parchment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep > 1 && currentStep < totalSteps {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: previousStep) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Back to step \(currentStep - 1)")
                    }
                }
            }
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 6) {
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .tint(AppTheme.terracotta)
                .padding(.horizontal, 20)
            
            Text("Step \(currentStep) of \(totalSteps)")
                .font(AppTypography.uiTag(size: 9, weight: .semibold))
                .foregroundColor(AppTheme.mutedWarmGray)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Onboarding step \(currentStep) of \(totalSteps)")
    }
    
    private func advanceStep() {
        if reduceMotion {
            if currentStep < totalSteps {
                currentStep += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                if currentStep < totalSteps {
                    currentStep += 1
                }
            }
        }
    }
    
    private func previousStep() {
        if reduceMotion {
            if currentStep > 1 {
                currentStep -= 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                if currentStep > 1 {
                    currentStep -= 1
                }
            }
        }
    }
    
    private func finishOnboarding() {
        if reduceMotion {
            UserSettingsService.shared.completeOnboarding()
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                UserSettingsService.shared.completeOnboarding()
            }
        }
    }
}
