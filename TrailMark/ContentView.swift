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
                .tabItem { Label("Today", systemImage: "sun.max.fill")
                }
            
            FieldJournalView()
                .tabItem { Label("Journal", systemImage: "waveform") }
            
            RecoveryView()
                .tabItem { Label("Recovery", systemImage: "bed.double.fill")
                }
            JourneyListView()
                .tabItem { Label("Journey", systemImage: "safari.fill")
                }
        }
      
        .task {
            await model.health.requestAuthorization()
            await model.health.refreshToday()
        }
    }
}

#Preview {
    ContentView()
}

