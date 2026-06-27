//
//  ContentView.swift
//  TrailMark
//
//  Created by Oscar Artemio Brito Ortiz on 23/06/26.
//

import SwiftUI
import TrailMarkCore


struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            TodayDashboardView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
        }
        .task {
            await model.health.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}

