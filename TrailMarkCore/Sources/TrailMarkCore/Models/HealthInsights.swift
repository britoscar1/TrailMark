import Foundation
import Combine

public struct SleepSummary: Equatable, Sendable, Codable {
    public var asleepSeconds: TimeInterval
    public var date: Date
    
    public init(asleepSeconds: TimeInterval = 0, date: Date = Date()){
        self.asleepSeconds = asleepSeconds
        self.date = date
    }
    
    public static let empty = SleepSummary()
    
    public var hours: Double { asleepSeconds / 3600 }
    
    public var durationText: String{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: asleepSeconds) ?? "-"
    }
    
}
public struct EnergyTrendPoint: Equatable, Sendable, Codable, Identifiable{
    public var id: Date { day }
    
    public var day: Date
    public var activeEnergyKcal: Double
    
    public init(day: Date, activeEnergyKcal: Double){
        self.day = day
        self.activeEnergyKcal = activeEnergyKcal
    }
}



