import SwiftUI

public enum AppTheme {
    // MARK: - Restrained Warm-Neutral Palette (Editorial Travel Aesthetic)
    
    /// Primary background: Warm off-white / parchment
    public static let parchment = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.08, blue: 0.08, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0)
    })
    
    /// Secondary surface: Clean warm off-white tile
    public static let parchmentSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 1.0)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    })
    
    /// Primary text: Very dark charcoal
    public static let charcoal = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0)
            : UIColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0)
    })
    
    /// Secondary text: Muted warm gray
    public static let mutedWarmGray = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.60, blue: 0.57, alpha: 1.0)
            : UIColor(red: 0.52, green: 0.50, blue: 0.47, alpha: 1.0)
    })
    
    /// Extremely subtle warm gray border
    public static let subtleWarmBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 0.6)
            : UIColor(red: 0.86, green: 0.84, blue: 0.80, alpha: 0.65)
    })
    
    /// Restrained Accent: Terracotta / burnt red (used sparingly for interaction and emphasis)
    public static let terracotta = Color(red: 0.76, green: 0.31, blue: 0.22)
    public static let terracottaSubtle = Color(red: 0.76, green: 0.31, blue: 0.22).opacity(0.12)
    public static let terracottaLight = Color(red: 0.76, green: 0.31, blue: 0.22).opacity(0.08)
    
    // Muted Editorial Tone Complements (Restrained, no neon)
    public static let sageOlive = Color(red: 0.32, green: 0.45, blue: 0.36)
    public static let sageOliveLight = Color(red: 0.32, green: 0.45, blue: 0.36).opacity(0.12)
    public static let deepIndigo = Color(red: 0.24, green: 0.33, blue: 0.44)
    public static let deepIndigoLight = Color(red: 0.24, green: 0.33, blue: 0.44).opacity(0.10)
    public static let warmOchre = Color(red: 0.80, green: 0.54, blue: 0.22)
    public static let warmOchreLight = Color(red: 0.80, green: 0.54, blue: 0.22).opacity(0.12)
    
    // Legacy / Backward-Compatible Aliases mapped to new editorial tokens
    public static let forestEmerald = sageOlive
    public static let forestEmeraldDark = Color(red: 0.20, green: 0.30, blue: 0.24)
    public static let forestEmeraldLight = sageOliveLight
    public static let horizonBlue = deepIndigo
    public static let horizonBlueLight = deepIndigoLight
    public static let dawnGold = warmOchre
    public static let dawnGoldLight = warmOchreLight
    public static let mistSlate = mutedWarmGray
    public static let primaryColor = terracotta
    public static let baseGreen = sageOlive
    public static let baseGreenLight = sageOliveLight
    public static let transitBlue = deepIndigo
    public static let transitBlueLight = deepIndigoLight
    public static let amberAccent = warmOchre
    public static let amberAccentLight = warmOchreLight
    public static let coralRed = terracotta
    
    // MARK: - Surfaces
    public static let cardBackground = parchmentSurface
    public static let groupedBackground = parchment
    public static let subtleBorder = subtleWarmBorder
    public static let elevationShadow = Color.black.opacity(0.03)
    
    // Subtle Editorial Gradients (Calm, non-decorative)
    public static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.15, blue: 0.14),
            Color(red: 0.10, green: 0.09, blue: 0.09)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let goldMedalGradient = LinearGradient(
        colors: [warmOchre, warmOchre.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let bronzeMedalGradient = LinearGradient(
        colors: [terracotta, terracotta.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let silverMedalGradient = LinearGradient(
        colors: [mutedWarmGray, mutedWarmGray.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Geometry & Radii
    public static let cardCornerRadius: CGFloat = 16.0
    public static let buttonCornerRadius: CGFloat = 12.0
    public static let inputCornerRadius: CGFloat = 10.0
    public static let cardPadding: CGFloat = 16.0
}

// MARK: - Typography Extensions
public enum AppTypography {
    /// Large editorial heading with generous spacing (for page titles, key destinations)
    public static func editorialTitle(size: CGFloat = 34, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    /// Destination / Place title in elegant serif
    public static func destinationTitle(size: CGFloat = 22, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    /// Subhead / Editorial commentary
    public static func editorialSubhead(size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    /// UI metadata, uppercase tracked caption
    public static func uiTag(size: CGFloat = 10, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Reusable Editorial Card View Modifier
public struct RoamlyCardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    public init(padding: CGFloat = AppTheme.cardPadding, cornerRadius: CGFloat = AppTheme.cardCornerRadius) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .shadow(color: AppTheme.elevationShadow, radius: 4, x: 0, y: 2)
    }
}

public extension View {
    func roamlyCard(padding: CGFloat = AppTheme.cardPadding, cornerRadius: CGFloat = AppTheme.cardCornerRadius) -> some View {
        self.modifier(RoamlyCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Surface Modifier
public struct RoamlyGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
    }
}

public extension View {
    func roamlyGlass(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(RoamlyGlassModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Restrained Primary Button Style
public struct RoamlyPrimaryButtonStyle: ButtonStyle {
    let height: CGFloat
    let backgroundColor: Color
    
    public init(height: CGFloat = 48, backgroundColor: Color = AppTheme.terracotta) {
        self.height = height
        self.backgroundColor = backgroundColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Restrained Secondary Button Style
public struct RoamlySecondaryButtonStyle: ButtonStyle {
    let tintColor: Color
    
    public init(tintColor: Color = AppTheme.charcoal) {
        self.tintColor = tintColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(tintColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Input View Modifier
public struct RoamlyInputModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(AppTheme.parchment)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.inputCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.inputCornerRadius, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
    }
}

public extension View {
    func roamlyInputStyle() -> some View {
        self.modifier(RoamlyInputModifier())
    }
}

// MARK: - Editorial Tag / Status Pill
public struct StatusPill: View {
    let title: String
    let icon: String?
    let color: Color
    
    public init(title: String, icon: String? = nil, color: Color = AppTheme.charcoal) {
        self.title = title
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(title.uppercased())
                .font(AppTypography.uiTag(size: 9, weight: .semibold))
                .tracking(0.6)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Clean Score Badge View (Editorial point indicator)
public struct ScoreBadgeView: View {
    let score: Int
    
    public init(score: Int) {
        self.score = score
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            Text("+\(score)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.charcoal)
            Text("pts")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(AppTheme.mutedWarmGray)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(AppTheme.parchment)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 0.75)
        )
    }
}

// MARK: - Section Header View
public struct SectionHeaderView: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(AppTypography.uiTag(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundColor(AppTheme.mutedWarmGray)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.terracotta)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
