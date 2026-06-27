//
//  appModel.swift
//  TrailMark
//
//  Created by Oscar Artemio Brito Ortiz on 25/06/26.
//

import Foundation
import Combine
import Observation
import TrailMarkCore


@MainActor
@Observable
final class AppModel {
    let health: HealthKitManager = HealthKitManager()
}
