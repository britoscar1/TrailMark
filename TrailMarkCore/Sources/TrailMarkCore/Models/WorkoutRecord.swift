import Foundation
import Combine

public struct WorkoutRecord: Identifiable, Hashable, Codable, Sendable{
    public var id: UUID
    public var start: Date
    public var end: Date
    public var activeEnergyKcal: Double
    public var distanceMeters: Double
    // Avg heart rate, will need heartrate sensor connected
    public var averageHeartRate: Double?
    
    public init(id: UUID = UUID(),
                start: Date,
                end: Date,
                activeEnergyKcal: Double = 0,
                distanceMeters: Double = 0,
                averageHeartRate: Double? = nil
    ){
        self.id = id
        self.start = start
        self.end = end
        self.activeEnergyKcal = activeEnergyKcal
        self.distanceMeters = distanceMeters
        self.averageHeartRate = averageHeartRate
    }
    
    //MARK: COMPUTED PROPERTIES
    // -  We need one duration computed property (end - start)
    
    // -  We need another one to represent the duration (time interval) into a formatted string like "00:00:00"
    //    use allowedUnits, and zeroFormattingBehavior(recommend .pad)
    // 1. Create a formatter (DateComponentFormatter)
    // 2. Set the formatter options
    // 3. return formatted string
    
    public var duration: TimeInterval {
        return end.timeIntervalSince(start)
    }
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour,.minute,.second]
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: duration) ?? "00:00:00"
    }
}


