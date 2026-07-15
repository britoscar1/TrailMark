//
//  HealthKit.swift
//  TrailMarkCore
//
//  Created by Oscar Artemio Brito Ortiz on 23/06/26.
//

import HealthKit
import Foundation
import Observation

@MainActor
@Observable
public final class HealthKitManager {
    public enum AuthorizationState: Equatable{
        case unknown
        case unavailable // device has no health data e.g. ipad, simulators,etc
        case requisiting
        case authorized
        case denied
    }
    public private(set) var todaySummary: ActivitySummary = .empty
    public private(set) var authorizationState: AuthorizationState = .unknown // consumer can read but cannot set
    public private(set) var sleep: SleepSummary = .empty 
    public private(set) var energyTrend: [EnergyTrendPoint] = []
    private let store = HKHealthStore()
    
    public init() {
        if !HKHealthStore.isHealthDataAvailable() {
            authorizationState = .unavailable
        }
    }
    
    private var stepsType: HKQuantityType{HKQuantityType(.stepCount)}
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning)}
    private var energyType: HKQuantityType{HKQuantityType(.activeEnergyBurned)}
    private var heartRateType: HKQuantityType {HKQuantityType(.heartRate)}
    private var sleepType: HKCategoryType {HKCategoryType (.sleepAnalysis)}
    
    //MARK: - HK Auth Model
    private var readTypes: Set<HKObjectType> {
        [stepsType, distanceType, energyType, heartRateType, sleepType, HKObjectType.workoutType()]
    }
    private var shareTypes: Set<HKSampleType> {
        [energyType, distanceType, HKObjectType.workoutType()]
    }
    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .unavailable
            return
        }
        authorizationState = .requisiting
        
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            // Note: for privacy ios never tells us wheter read access was granted
            // We treat the request completed as authorized and let zeroed summary in screen
            authorizationState = .authorized
        } catch {
            authorizationState = .denied
        }
    }
    //MARK: - HK Queries
    
    public func refreshToday() async {
        guard authorizationState == .authorized else {return}
        // create time Predicate
        let calendar = Calendar.current
        let now = Date() // ISO6001 2026-06-25T17:14:12.000+11:00
        let startOfDay = calendar.startOfDay(for: now)
        
        async let steps = getSumQuantityFromStartDate(stepsType, unit: .count(), since: startOfDay)
        async let distance = getSumQuantityFromStartDate(distanceType, unit: .meter(), since: startOfDay)
        async let energy = getSumQuantityFromStartDate(energyType, unit: .kilocalorie(), since: startOfDay)
        
        todaySummary = ActivitySummary(
            steps: await steps,
            distanceMeters: await distance,
            activeEnergeKcal: await energy,
            date: startOfDay
        )
        
    }
    private func getSumQuantityFromStartDate(_ type: HKQuantityType, unit: HKUnit, since start: Date) async -> Double {
        
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) {_, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for:unit) ?? 0
                continuation.resume(returning: value)
                
            }
            store.execute(query)
        }
        
    }
    
    //This function returns the most recent available heart rate measure
    // from healthstore
    private func getLatestHeartRate() async -> Double {
        let unit = HKUnit.count().unitDivided(by: .minute())
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) {_, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: bpm)
                
            }
            store.execute(query)
        }
        
    }
    
    //builds a daily active energy collection for the last 7 days using
    // HKStatisticsCollectionQuery, then maps it to chart points (EnergyTrendPoint)
    
    public func refreshEnergyTrend() async {
        // 1. check for the auth state
        // 2. calculate dates for the time predicate
        // 3. set checked continuation and return vaiable
        // 3.1 make the actual query
        // 3.2 create the data handler/closure
        // 3.3 Execute query
        // 4. set data to new property
        
        guard authorizationState == .authorized else {return}
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let trendEndDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return }
        
        let trend: [EnergyTrendPoint] = await withCheckedContinuation { continuation in
            var interval = DateComponents()
            interval.day = 1
            let predicate = HKQuery.predicateForSamples(withStart: trendEndDate, end: Date())
            let query = HKStatisticsCollectionQuery(quantityType: energyType,
                                                    quantitySamplePredicate: predicate,
                                                    options: .cumulativeSum,
                                                    anchorDate: trendEndDate,
                                                    intervalComponents: interval)
            query.initialResultsHandler = { _, results, _ in
                var points: [EnergyTrendPoint] = []
                results?.enumerateStatistics(from: trendEndDate, to: Date()) { stats, _ in
                    let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    points.append(EnergyTrendPoint(day: stats.startDate, activeEnergyKcal: kcal))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
        energyTrend = trend
        
    }
    
    
    public func refreshLastNightSleep() async {
        guard authorizationState == .authorized else { return }
        // Let's define a night as the time between 6pm to 12pm
        let calendar = Calendar.current
        let now = Date()
        
        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let sixPmYesterday = calendar.date(byAdding: .hour,value: -18, to: noonToday) ?? now
        
        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: sixPmYesterday, end: noonToday)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) {_, results, _ in // result at this point is just an HKSample
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [] )
            }
            
            store.execute(query)
        }
        let asleepValidStateRawValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        
        let total = samples
            .filter {asleepValidStateRawValues.contains($0.value)} // returns true only for valid sleep states
            .reduce(0) { $0 + $1.endDate.timeIntervalSince( $1.startDate)
            }
        
    }
    
        
        
    public func save(_ record: WorkoutRecord, acivity: HKWorkoutActivityType = .walking) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = acivity
            
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
            
        try await builder.beginCollection(at: record.start)
            
        var samples: [HKSample] = []
        if record.activeEnergyKcal > 0{
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: record.activeEnergyKcal)
            samples.append(HKCumulativeQuantitySample(type: distanceType, quantity: quantity, start: record.start, end: record.end))
        }
            
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }
            
        try await builder.endCollection(at: record.end)
        _ = try await builder.finishWorkout()
    }
}
    






