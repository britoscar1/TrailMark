//
//  TodayDashboardView.swift
//  TrailMark
//
//  Created by Oscar Artemio Brito Ortiz on 25/06/26.
//

import SwiftUI
import TrailMarkCore

struct TodayDashboardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                switch model.health.authorizationState {
                case .unavailable:
                    ContentUnavailableView(
                        "Health Data Unavailable",
                        systemImage: "heart.slash",
                        description: Text("This device can't provide health data")
                    )
                case .denied:
                    ContentUnavailableView {
                        Label("Health Access Needed", systemImage: "lock.fill")
                    } description: {
                        Text("TrailMark requires health access to work")
                    } actions: {
                        Button("Try Again") {
                            Task {
                                await model.health.requestAuthorization()
                                await model.health.refreshToday()
                            }
                        }
                    }

                default:
                    summary
                }
            }
            .navigationTitle("Today")
            .task { await model.health.refreshToday() }
            .refreshable { await model.health.refreshToday() }
        }
    }

    private var summary: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricCard(title: "Steps", value: "\(Int(model.health.todaySummary.steps))", symbol: "figure.walk", tint: .orange)
                MetricCard(title: "Distance", value: "\(Int(model.health.todaySummary.distanceMeters))m", symbol: "point.topleft.down.curvedto.point.bottomright.up", tint: .teal)
                MetricCard(title: "Active Energy", value: "\(Int(model.health.todaySummary.activeEnergeKcal)) kcal", symbol: "flame.fill", tint: .red)
            }
            .padding()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundColor(tint)
                .frame(width: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TodayDashboardView()
        .environment(AppModel())
}
