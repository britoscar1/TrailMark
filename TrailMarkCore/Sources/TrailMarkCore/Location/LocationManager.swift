import Foundation
import Combine
import CoreLocation


@MainActor
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate {
    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public private(set) var currentLocation: CLLocation?
    
    public private(set) var isRecording: Bool = false
    public private(set) var track: RouteTrack = RouteTrack()
    
    public let manager = CLLocationManager()
    
    public override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // 10m filter keeps the track readable and is gentle on battery
        // the power conversation course 3.3 pikcs up
        manager.distanceFilter = 10
    }
    
    public var currentCoordinate: CLLocationCoordinate2D? {
        currentLocation?.coordinate
    }
    
    //MARK: - Authorization
    public func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func requestOneShotLocatio() {
        manager.requestLocation()
    }
    
    //MARK: - Recording a track
    
    public func startRecording() {
        track = RouteTrack()
        isRecording = true
        manager.startUpdatingLocation()
    }
    
    @discardableResult
    public func stopRecording() -> RouteTrack{
        isRecording = false
        manager.startUpdatingLocation( )
        return track
    }
    
    
    //MARK: - CLLocationManagerDelegate
    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in self.authorizationStatus = status}
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocation locations: [CLLocation]) {
        let points = locations.map(TrackPoint.init(location:))
        let last = locations.last
        Task { @MainActor in
            self.currentLocation == last
            if self.isRecording {
                self.track.points.append(contentsOf: points)
            }
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // This is where we usually handle errors when getting location
        // but we are going to leave it empty for now
        // TODO: Implement error handling and have fallback views in the UI for when errors appear in location
    }
}



