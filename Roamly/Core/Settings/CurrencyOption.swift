import Foundation

public struct CurrencyOption: Identifiable, Hashable, Sendable {
    public let code: String
    public let name: String
    public let fallbackSymbol: String
    
    public var id: String { code }
    
    public init(code: String, name: String, fallbackSymbol: String) {
        self.code = code
        self.name = name
        self.fallbackSymbol = fallbackSymbol
    }
    
    /// Returns the localized currency symbol derived via Apple's Foundation Locale APIs.
    public var symbol: String {
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeIdentifier)
        return locale.currencySymbol ?? fallbackSymbol
    }
    
    public static let supportedCurrencies: [CurrencyOption] = [
        CurrencyOption(code: "INR", name: "Indian Rupee", fallbackSymbol: "₹"),
        CurrencyOption(code: "USD", name: "US Dollar", fallbackSymbol: "$"),
        CurrencyOption(code: "EUR", name: "Euro", fallbackSymbol: "€"),
        CurrencyOption(code: "GBP", name: "British Pound", fallbackSymbol: "£"),
        CurrencyOption(code: "JPY", name: "Japanese Yen", fallbackSymbol: "¥"),
        CurrencyOption(code: "AUD", name: "Australian Dollar", fallbackSymbol: "A$"),
        CurrencyOption(code: "CAD", name: "Canadian Dollar", fallbackSymbol: "C$"),
        CurrencyOption(code: "SGD", name: "Singapore Dollar", fallbackSymbol: "S$"),
        CurrencyOption(code: "AED", name: "UAE Dirham", fallbackSymbol: "د.إ"),
        CurrencyOption(code: "CHF", name: "Swiss Franc", fallbackSymbol: "CHF")
    ]
    
    public static func find(byCode code: String) -> CurrencyOption? {
        supportedCurrencies.first { $0.code.uppercased() == code.uppercased() }
    }
    
    public static var defaultCurrency: CurrencyOption {
        // Try device locale currency code if supported, else USD
        if let deviceCurrency = Locale.current.currency?.identifier,
           let match = find(byCode: deviceCurrency) {
            return match
        }
        return supportedCurrencies.first { $0.code == "USD" } ?? supportedCurrencies[1]
    }
}
