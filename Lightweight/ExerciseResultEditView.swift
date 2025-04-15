import SwiftUI
import SwiftData

struct ExerciseResultEditView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.appSettings) private var appSettings
  @Bindable var result: ExerciseResult
  let isNew: Bool

  // For time input
  @State private var hours = 0
  @State private var minutes = 0
  @State private var seconds = 0
  @State private var milliseconds = 0

  // For reps input
  @State private var repsCount: Int = 0

  var body: some View {
    Form {
      Section {
        DatePicker("Date", selection: $result.date, displayedComponents: [.date])
      }

      switch result.exercise?.scoreType {
      case .time:
        Section("Time") {
          HStack {
            Picker("Hours", selection: $hours) {
              ForEach(0..<24) { hour in
                Text("\(hour)").tag(hour)
              }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)

            Text(":")

            Picker("Minutes", selection: $minutes) {
              ForEach(0..<60) { minute in
                Text(String(format: "%02d", minute)).tag(minute)
              }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)

            Text(":")

            Picker("Seconds", selection: $seconds) {
              ForEach(0..<60) { second in
                Text(String(format: "%02d", second)).tag(second)
              }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
          }
          .onChange(of: [hours, minutes, seconds, milliseconds]) {
            updateTimeInterval()
          }
        }

      case .weight:
        Section("Weight") {
          HStack {
            TextField("Weight", value: $result.weight, format: .number)
              .keyboardType(.numberPad)
            Text(appSettings.weightUnit.rawValue)
          }

          VStack {
            HStack {
              Text("Reps:")
              TextField("Reps", value: $repsCount, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            }

            Stepper("", value: $repsCount)
          }
          .onChange(of: repsCount) {
            result.reps = repsCount
          }
        }

      case .reps:
        Section("Reps") {
          VStack {
            HStack {
              Text("Reps:")
              TextField("Reps", value: $repsCount, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            }

            Stepper("", value: $repsCount)
          }
          .onChange(of: repsCount) {
            result.reps = repsCount
          }
        }

      case .other:
        Section(result.exercise?.otherUnits ?? "Value") {
          TextField("Value", value: $result.otherUnit, format: .number)
            .keyboardType(.decimalPad)
        }

      case .none:
        EmptyView()
      }

      Section("Notes") {
        TextField("Notes", text: .init(
          get: { self.result.notes ?? "" },
          set: { self.result.notes = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
        .lineLimit(1...10)
      }
    }
    .navigationTitle(result.exercise?.name ?? "New Result")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          if isNew {
            modelContext.insert(result)
          }
          dismiss()
        }
      }
    }
    .onAppear {
      if let time = result.time {
        hours = Int(time) / 3600
        minutes = Int(time) / 60 % 60
        seconds = Int(time) % 60
        milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
      }
      repsCount = result.reps ?? 0
    }
  }

  private func updateTimeInterval() {
    let totalSeconds = TimeInterval(hours * 3600 + minutes * 60 + seconds)
    let totalMilliseconds = TimeInterval(milliseconds) / 1000.0
    result.time = totalSeconds + totalMilliseconds
  }
}

#Preview {
  NavigationStack {
    ExerciseResultEditView(result: LightweightApp.DataController.previewContainer.mainContext.exerciseWithSampleResults().results.first!, isNew: false)
  }
  .modelContainer(LightweightApp.DataController.previewContainer)
}
