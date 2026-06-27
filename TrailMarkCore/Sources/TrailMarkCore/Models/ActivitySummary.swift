//
//  ActivitySummary.swift
//  TrailMarkCore
//
//  Created by Oscar Artemio Brito Ortiz on 23/06/26.
//

import Foundation

public struct ActivitySummary: Sendable, Equatable {
    public var steps: Double = 0
    public var distanceMeters: Double
    public var activeEnergeKcal: Double
    public var date: Date
    
    public init(steps: Double = 0, distanceMeters: Double = 0, activeEnergeKcal: Double = 0 , date: Date = Date()) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.activeEnergeKcal = activeEnergeKcal
        self.date = date
    }
    public static let empty = ActivitySummary()
    
}
