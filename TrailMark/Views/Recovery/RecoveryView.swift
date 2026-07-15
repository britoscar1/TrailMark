import SwiftUI
import Charts
import TrailMarkCore


struct MockDataForRecovery {
    static var mockActivityTrend: [EnergyTrendPoint] {
        let calendar: Calendar = .current
        let today: Date = calendar.startOfDay(for: .now)
        
        let mockKcal: [Double] = [320, 540, 690, 180, 730, 495, 660]
        
        let mockTrend: [EnergyTrendPoint] = mockKcal.enumerated().compactMap { index, kcal -> EnergyTrendPoint? in
            guard let day = calendar.date(byAdding: .day, value: index - 6, to: today)  else { return nil }
            return EnergyTrendPoint(day: day, activeEnergyKcal: kcal)
        }
        return mockTrend
    }
    
}
struct RecoveryView: View {
    @Environment(AppModel.self) private var model
    
    @State private var saveState: SaveState = .idle
    
    enum SaveState: Equatable {
        case idle, saving, saved, failed(String)
    }
    
    var body: some View{
        NavigationStack{
            ScrollView{
                VStack(spacing:  16) {
                    // 1. Sleep card, cards with the sleep data
                    sleepCard
                    // 2. Energy chart; 7-days trend for energy
                    energyChartCard
                    // 3. saveWorkoutCard;
                    saveWorkoutCard
                }
                .padding()
            }
            .navigationTitle(Text("Recovery"))
            .task{
                await model.health.refreshLastNightSleep()
                await model.health.refreshEnergyTrend()
            }
            .refreshable {
                await model.health.refreshLastNightSleep()
                await model.health.refreshEnergyTrend()
            }
        }
    }
    private var sleepCard: some View {
//        model.health.sleep.asleepSeconds
//        model.health.sleep.durationText
        VStack(alignment: .leading, spacing: 16){
            Label("Sleep Data", systemImage: "bed.double.fill")
                .font(.headline)
            
            /* if model.health.sleep.asleepSeconds.isZero {
                Text("No Sleep Data Yet")
                    .foregroundStyle(Color.secondary)
            } else { */
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(Color.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Asleep")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(model.health.sleep.durationText)
                            .font(.caption)
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var energyChartCard: some View{
        VStack( alignment: .leading, spacing: 12) {
            Label("Active Energy - Last 7 Days", systemImage: "flame.fill")
                .font(.headline)
            
            if model.health.energyTrend.isEmpty {
                Text("No Energy Data Yet").foregroundStyle(Color.secondary)
            } else {
                Chart(model.health.energyTrend) { point in
                    BarMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("kcal", point.activeEnergyKcal)
                    )
                    .foregroundStyle(.red.gradient)
                }
                .chartXAxis{
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    }
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var saveWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12){
            Label("Log a sample workout", systemImage: "figure.walking")
                .font(.headline)
            
            Text("Saves a 30-min walk to HK so we can confirm appears in the health app")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
            
            Button(action: saveSampleWorkout) {
                HStack {
                    if saveState == .saving {
                        ProgressView().padding(.trailing, 4)
                    }
                    Text(buttonTitle)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color.white)
            }
            .disabled(saveState == .saving)
            
            if case .failed(let message) = saveState {
                Text(message).font(.footnote).foregroundStyle(Color.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var buttonTitle: String {
        switch saveState {
        case .saved: return "Saved"
        default: return "Save Sample Workout"
        }
    }
    private func saveSampleWorkout() {
        saveState = .saving
        let end = Date()
        let record = WorkoutRecord(start: end.addingTimeInterval(-1800), end: end, activeEnergyKcal: 100, distanceMeters: 2400)
        
        Task{
            do{
                try await model.health.save(record)
                saveState = .saved
                await model.health.refreshEnergyTrend()
            } catch {
                saveState = .failed(error.localizedDescription)
            }
        }
    }
}

#Preview{
    RecoveryView()
        .environment(AppModel())
}



