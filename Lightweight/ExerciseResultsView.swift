import SwiftUI
import SwiftData

struct ExerciseResultsView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.appSettings) private var appSettings
  @Bindable var exercise: Exercise
  @Query private var results: [ExerciseResult]
  @State private var isEditingName = false
  @State private var exerciseName: String = ""
  @State private var exerciseDetail: String = ""
  @State private var showingNewResult = false
  @State private var newResult: ExerciseResult?

  init(exercise: Exercise) {
    self.exercise = exercise
    let exerciseUUID = exercise.uuid
    _results = Query(
      filter: #Predicate<ExerciseResult> { result in
        result.exercise?.uuid == exerciseUUID
      },
      sort: [
        SortDescriptor(\ExerciseResult.weight, order: .reverse),
        SortDescriptor(\ExerciseResult.reps, order: .reverse),
        SortDescriptor(\ExerciseResult.time, order: .forward),
        SortDescriptor(\ExerciseResult.otherUnit, order: .reverse)
      ]
    )
  }

  var body: some View {
    List {
      ForEach(results) { result in
        NavigationLink(destination: ExerciseResultEditView(result: result, isNew: false)) {
          HStack {
            resultDisplay(for: result)
            Spacer()
            Text(result.date, format: .dateTime.day().month())
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .listStyle(.plain)
    .background(Color(.systemBackground))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Button(action: {
          exerciseName = exercise.name
          exerciseDetail = exercise.detail ?? ""
          isEditingName = true
        }) {
          VStack(spacing: 2) {
            Text(exercise.name)
              .font(.headline)
            if let detail = exercise.detail {
              Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: {
          newResult = ExerciseResult(exercise: exercise)
          showingNewResult = true
        }) {
          Label("Add Result", systemImage: "plus")
        }
      }
    }
    .alert("Edit Exercise", isPresented: $isEditingName) {
      TextField("Exercise Name", text: $exerciseName)
      TextField("Detail (optional)", text: $exerciseDetail)
      Button("Cancel", role: .cancel) { }
      Button("Save") {
        exercise.name = exerciseName
        exercise.detail = exerciseDetail.isEmpty ? nil : exerciseDetail
      }
    }
    .sheet(isPresented: $showingNewResult, onDismiss: {
      if newResult?.modelContext == nil {
        newResult = nil
      }
    }) {
      if let result = newResult {
        NavigationStack {
          ExerciseResultEditView(result: result, isNew: true)
        }
      }
    }
  }

  @ViewBuilder
  private func resultDisplay(for result: ExerciseResult) -> some View {
    switch exercise.scoreType {
    case .time:
      if let time = result.time {
        Text(formatTime(time))
      }
    case .weight:
      if let weight = result.weight {
        HStack(spacing: 4) {
          Text("\(appSettings.weightUnit == .kilograms ? weight : Int(Double(weight) * 2.20462)) \(appSettings.weightUnit.rawValue)")
          if let reps = result.reps {
            Text("^[\(reps) rep](inflect: true)")
              .foregroundStyle(.secondary)
              .textCase(.lowercase)
          }
        }
      }
    case .reps:
      if let reps = result.reps {
        Text("^[\(reps) rep](inflect: true)")
          .textCase(.lowercase)
      }
    case .other:
      if let value = result.otherUnit, let units = exercise.otherUnits?.lowercased() {
        let formattedValue = String(format: "%.3g", value)
        Text("^[\(formattedValue) \(units)](inflect: true)")
      }
    }
  }

  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) / 60 % 60
    let seconds = Int(timeInterval) % 60
    let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else if minutes > 0 {
      return String(format: "%d:%02d", minutes, seconds)
    } else {
      return String(format: "%d.%03d", seconds, milliseconds)
    }
  }

  private func addNewResult() {
    showingNewResult = true
  }
}

#Preview {
  NavigationStack {
    ExerciseResultsView(exercise: LightweightApp.DataController.previewContainer.mainContext.exerciseWithSampleResults())
  }
  .modelContainer(LightweightApp.DataController.previewContainer)
}

extension ModelContext {
  func exerciseWithSampleResults() -> Exercise {
    let exercise = Exercise(name: "Back Squat", scoreType: .weight)

    let result1 = ExerciseResult(
      exercise: exercise,
      date: .now,
      weight: 225,
      reps: 5
    )

    let result2 = ExerciseResult(
      exercise: exercise,
      date: .now.addingTimeInterval(-86400),
      weight: 215,
      reps: 1
    )

    self.insert(exercise)
    self.insert(result1)
    self.insert(result2)

    return exercise
  }
}
