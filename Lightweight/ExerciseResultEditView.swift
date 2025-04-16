import SwiftUI
import SwiftData

struct ExerciseResultEditView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.appSettings) private var appSettings
  let result: ExerciseResult
  let isNew: Bool

  // For time input
  @State private var hours = 0
  @State private var minutes = 0
  @State private var seconds = 0
  @State private var milliseconds = 0

  // Local state to prevent constant updates
  @State private var localDate: Date 
  @State private var localWeight: Int?
  @State private var localReps: Int = 0
  @State private var localNotes: String = ""
  @State private var localOtherUnit: Double?

  init(result: ExerciseResult, isNew: Bool) {
    self.result = result
    self.isNew = isNew
    _localDate = State(initialValue: result.date)
    _localWeight = State(initialValue: result.weight)
    _localReps = State(initialValue: result.reps ?? 0)
    _localNotes = State(initialValue: result.notes ?? "")
    _localOtherUnit = State(initialValue: result.otherUnit)

    if let time = result.time {
      _hours = State(initialValue: Int(time) / 3600)
      _minutes = State(initialValue: Int(time) / 60 % 60)
      _seconds = State(initialValue: Int(time) % 60)
      _milliseconds = State(initialValue: Int((time.truncatingRemainder(dividingBy: 1)) * 1000))
    }
  }

  var body: some View {
    Form {
      Section {
        DatePicker("Date", selection: $localDate, displayedComponents: [.date])
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
        }

      case .weight:
        Section("Weight") {
          HStack {
            TextField("Weight", value: $localWeight, format: .number)
              .keyboardType(.numberPad)
            Text(appSettings.weightUnit.rawValue)
          }

          VStack {
            HStack {
              Text("Reps:")
              TextField("Reps", value: $localReps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            }

            Stepper("", value: $localReps)
          }
        }

      case .reps:
        Section("Reps") {
          VStack {
            HStack {
              Text("Reps:")
              TextField("Reps", value: $localReps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            }

            Stepper("", value: $localReps)
          }
        }

      case .other:
        Section(result.exercise?.otherUnits ?? "Value") {
          TextField("Value", value: $localOtherUnit, format: .number)
            .keyboardType(.decimalPad)
        }

      case .none:
        EmptyView()
      }

      Section("Notes") {
        TextField("Notes", text: $localNotes, axis: .vertical)
          .lineLimit(1...10)
      }

      if !isNew {
        Section {
          Button(role: .destructive) {
            modelContext.delete(result)
            dismiss()
          } label: {
            HStack {
              Spacer()
              Text("Delete Result")
              Spacer()
            }
          }
        }
      }
    }
    .navigationTitle(result.exercise?.name ?? "New Result")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          saveChanges()
          if isNew {
            modelContext.insert(result)
          }
          dismiss()
        }
      }
    }
    .onAppear {
      // Initialize local state
      localDate = result.date
      localWeight = result.weight
      localReps = result.reps ?? 0
      localNotes = result.notes ?? ""
      localOtherUnit = result.otherUnit

      if let time = result.time {
        hours = Int(time) / 3600
        minutes = Int(time) / 60 % 60
        seconds = Int(time) % 60
        milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
      }
    }
  }

  private func calculateTimeInterval() -> TimeInterval {
    let totalSeconds = TimeInterval(hours * 3600 + minutes * 60 + seconds)
    let totalMilliseconds = TimeInterval(milliseconds) / 1000.0
    return totalSeconds + totalMilliseconds
  }

  private func saveChanges() {
    // Update all properties at once when saving
    result.date = localDate
    if result.exercise?.scoreType == .time {
      result.time = calculateTimeInterval()
    }
    result.weight = localWeight
    result.reps = localReps == 0 ? nil : localReps
    result.notes = localNotes.isEmpty ? nil : localNotes
    result.otherUnit = localOtherUnit
  }
}
