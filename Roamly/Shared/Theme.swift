import SwiftUI

public enum AppTheme {
    public static let primaryColor = Color.accentColor
    public static let baseGreen = Color(red: 0.13, green: 0.58, blue: 0.38)
    public static let transitBlue = Color(red: 0.12, green: 0.45, blue: 0.85)
    public static let amberAccent = Color(red: 0.95, green: 0.60, blue: 0.10)
    public static let coralRed = Color(red: 0.92, green: 0.30, blue: 0.25)
    
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)
}

public struct StatusPill: View {
    let title: String
    let icon: String
    let color: Color
    
    public init(title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.bold())
            Text(title)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

public struct ScoreBadgeView: View {
    let score: Int
    
    public init(score: Int) {
        self.score = score
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption.bold())
                .foregroundColor(.yellow)
            Text("+\(score) pts")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.18))
        .clipShape(Capsule())
    }
}
