import Foundation
import SwiftUI
import Observation

public enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    public var description: String {
        switch self {
        case .system:
            return "Roamly follows your iPhone's appearance automatically."
        case .light:
            return "Always use the warm parchment light appearance."
        case .dark:
            return "Always use the deep charcoal dark appearance."
        }
    }
}

@Observable
public final class UserSettingsService {
    public static let shared = UserSettingsService()
    
    private enum Keys {
        static let hasCompletedOnboarding = "roamly.settings.hasCompletedOnboarding"
        static let currencyCode = "roamly.settings.currencyCode"
        static let appAppearance = "roamly.settings.appAppearance"
    }
    
    public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    public var currencyCode: String {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: Keys.currencyCode)
        }
    }
    
    public var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appAppearance)
        }
    }
    
    public var currentCurrency: CurrencyOption {
        CurrencyOption.find(byCode: currencyCode) ?? CurrencyOption.defaultCurrency
    }
    
    public init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        let storedCurrency = UserDefaults.standard.string(forKey: Keys.currencyCode)
        self.currencyCode = storedCurrency ?? CurrencyOption.defaultCurrency.code
        
        if let storedAppearance = UserDefaults.standard.string(forKey: Keys.appAppearance),
           let parsed = AppAppearance(rawValue: storedAppearance) {
            self.appearance = parsed
        } else {
            self.appearance = .system
        }
    }
    
    public func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
    
    public func resetOnboarding() {
        self.hasCompletedOnboarding = false
    }
    
    public func updateCurrency(to code: String) {
        self.currencyCode = code.uppercased()
    }
    
    public func updateAppearance(to appearance: AppAppearance) {
        self.appearance = appearance
    }
}
