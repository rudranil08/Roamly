import Foundation

public enum DestinationCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case worldHeritage
    case museum
    case nationalPark
    case botanicalGarden
    case university
    case publicPark
    case foodMarket
    case commercial
    case transitHub
    case uncategorized
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .worldHeritage: return "World Heritage / Landmark"
        case .museum: return "Museum / Cultural Site"
        case .nationalPark: return "National Park / Reserve"
        case .botanicalGarden: return "Garden / Zoo"
        case .university: return "University Campus"
        case .publicPark: return "Public Park / Beach"
        case .foodMarket: return "Market / Culinary"
        case .commercial: return "Shopping / Business"
        case .transitHub: return "Transit Hub"
        case .uncategorized: return "Point of Interest"
        }
    }
    
    public var significanceMultiplier: Double {
        switch self {
        case .worldHeritage: return 3.5
        case .museum: return 3.0
        case .nationalPark: return 2.8
        case .botanicalGarden: return 2.2
        case .university: return 1.8
        case .publicPark: return 1.5
        case .foodMarket: return 1.2
        case .commercial: return 1.0
        case .transitHub: return 1.0
        case .uncategorized: return 0.8
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .worldHeritage: return "star.fill"
        case .museum: return "building.columns.fill"
        case .nationalPark: return "tree.fill"
        case .botanicalGarden: return "leaf.fill"
        case .university: return "graduationcap.fill"
        case .publicPark: return "sun.max.fill"
        case .foodMarket: return "fork.knife"
        case .commercial: return "cart.fill"
        case .transitHub: return "tram.fill"
        case .uncategorized: return "mappin.and.ellipse"
        }
    }
}
