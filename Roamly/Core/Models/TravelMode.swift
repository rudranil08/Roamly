import Foundation

public enum TravelMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case walking
    case running
    case cycling
    case eBike
    case scooter
    case train
    case metro
    case tram
    case bus
    case ferry
    case carpool
    case privateCar
    case taxi
    case rideshare
    case motorcycle
    case airplane
    case other
    case unknown
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Bicycle"
        case .eBike: return "E-Bike"
        case .scooter: return "Scooter"
        case .train: return "Train"
        case .metro: return "Metro / Subway"
        case .tram: return "Tram"
        case .bus: return "Public Bus"
        case .ferry: return "Ferry"
        case .carpool: return "Carpool"
        case .privateCar: return "Personal Car"
        case .taxi: return "Taxi / Cab"
        case .rideshare: return "Rideshare"
        case .motorcycle: return "Motorcycle"
        case .airplane: return "Airplane"
        case .other: return "Other"
        case .unknown: return "Unknown"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .eBike: return "bolt.car"
        case .scooter: return "scooter"
        case .train: return "train.side.front.car"
        case .metro: return "tram.fill"
        case .tram: return "cablecar"
        case .bus: return "bus.fill"
        case .ferry: return "ferry.fill"
        case .carpool: return "person.2.fill"
        case .privateCar: return "car.fill"
        case .taxi: return "car.side.fill"
        case .rideshare: return "car.2.fill"
        case .motorcycle: return "motorcycle.fill"
        case .airplane: return "airplane"
        case .other: return "ellipsis.circle"
        case .unknown: return "questionmark.circle"
        }
    }
    
    public var sustainabilityMultiplier: Double {
        switch self {
        case .walking, .running: return 2.5
        case .cycling, .eBike, .scooter: return 2.0
        case .train, .metro, .tram, .ferry: return 1.8
        case .bus: return 1.4
        case .carpool: return 1.2
        case .privateCar, .taxi, .rideshare, .motorcycle: return 0.7
        case .airplane: return 0.5
        case .other, .unknown: return 0.5
        }
    }
    
    public var categoryName: String {
        switch self {
        case .walking, .running: return "Human-Powered"
        case .cycling, .eBike, .scooter: return "Micromobility"
        case .train, .metro, .tram, .ferry, .bus: return "Public Transit"
        case .carpool, .rideshare: return "Shared Transit"
        case .privateCar, .taxi, .motorcycle: return "Motorized"
        case .airplane: return "Aviation"
        case .other, .unknown: return "Other"
        }
    }
}
