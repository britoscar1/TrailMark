import Foundation
import Combine
import CoreLocation

public struct TrackPoint: Hashable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var timeStamp: Date
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double,
        timeStamp: Date = Date()
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timeStamp = timeStamp
        
    }
    
    public init(location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timeStamp: location.timestamp
        )
    }
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


public struct RouteTrack: Hashable, Sendable, Codable {
    public var points: [TrackPoint]
    
    public init(points: [TrackPoint] = []){
        self.points = points
    }
    public var coordinates: [CLLocationCoordinate2D]{
        points.map(\.coordinate)
    }
    
    public var distanceMeters: Double {
        guard points.count > 1 else { return 0}
        
        var total: Double = 0
        
        for i in 1..<points.count {
            let prevElement = points[i - 1]
            let currentElement = points[i]
            
            let a = CLLocation(latitude: prevElement.latitude, longitude: prevElement.longitude)
            let b = CLLocation(latitude: currentElement.latitude, longitude: currentElement.longitude)
            
            total += b.distance(from: a)
        }
        return total
    }
    
    public var isEmpty: Bool {points.isEmpty}
}

