import Foundation

public struct CurrencyService {
    /// Formats a financial amount with its ISO 4217 currency code using Apple's Foundation NumberFormatter.
    public static func format(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return formatted
        }
        
        // Fallback
        let symbol = symbol(for: currencyCode)
        return String(format: "%@%.2f", symbol, amount)
    }
    
    /// Derives the localized symbol for a given ISO 4217 code.
    public static func symbol(for currencyCode: String) -> String {
        if let option = CurrencyOption.find(byCode: currencyCode) {
            return option.symbol
        }
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode])
        let locale = Locale(identifier: localeIdentifier)
        return locale.currencySymbol ?? currencyCode
    }
}
