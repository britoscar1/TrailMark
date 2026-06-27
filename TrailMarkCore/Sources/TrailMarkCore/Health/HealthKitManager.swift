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
    }




