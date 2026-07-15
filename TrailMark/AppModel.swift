import Foundation
import Combine
import Observation
import TrailMarkCore


@MainActor
@Observable
final class AppModel {
    let health: HealthKitManager = HealthKitManager()
    let media: MediaStore = MediaStore()
    let location: LocationManager = LocationManager()
    let journeys: JourneyStore = JourneyStore()
    
}
