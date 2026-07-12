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
  @State private var sortMode: SortMode = .best

  enum SortMode: String, CaseIterable, Identifiable {
    case best = "Best"
    case recent = "Recent"
    var id: String { rawValue }
  }

  init(exercise: Exercise) {
    self.exercise = exercise
    let exerciseUUID = exercise.uuid
    // Query newest-first; "Best" ordering is applied in-memory so the toggle
    // can switch instantly without rebuilding the query.
    _results = Query(
      filter: #Predicate<ExerciseResult> { result in
        result.exercise?.uuid == exerciseUUID
      },
      sort: [SortDescriptor(\ExerciseResult.date, order: .reverse)]
    )
  }

  /// True when `a` is a better result than `b` for this exercise's score type.
  private func isBetter(_ a: ExerciseResult, than b: ExerciseResult) -> Bool {
    switch exercise.scoreType {
    case .weight:
      return (OneRepMax.estimatedKg(for: a) ?? 0) > (OneRepMax.estimatedKg(for: b) ?? 0)
    case .reps:
      return (a.reps ?? 0) > (b.reps ?? 0)
    case .time:
      return (a.time ?? .greatestFiniteMagnitude) < (b.time ?? .greatestFiniteMagnitude)
    case .other:
      return (a.otherUnit ?? 0) > (b.otherUnit ?? 0)
    }
  }

  private var displayedResults: [ExerciseResult] {
    switch sortMode {
    case .recent: return results
    case .best: return results.sorted { isBetter($0, than: $1) }
    }
  }

  private var bestResult: ExerciseResult? {
    results.sorted { isBetter($0, than: $1) }.first
  }

  /// Estimated 1RM of the best set, in the user's unit. Weight exercises only.
  private var bestOneRepMax: Double? {
    guard exercise.scoreType == .weight,
          let best = bestResult,
          let kg = OneRepMax.estimatedKg(for: best) else { return nil }
    return appSettings.weightUnit.fromKilograms(kg)
  }

  /// A new result prefilled from the most recent set, so repeating a workout
  /// takes as few taps as possible.
  private func makeNewResult() -> ExerciseResult {
    let mostRecent = results.first // query is newest-first
    return ExerciseResult(
      exercise: exercise,
      date: Date(),
      weightKg: mostRecent?.weightKg,
      reps: mostRecent?.reps,
      time: mostRecent?.time,
      otherUnit: mostRecent?.otherUnit
    )
  }

  private func startNewResult() {
    newResult = makeNewResult()
    showingNewResult = true
  }

  var body: some View {
    Group {
      if results.isEmpty {
        EmptyStateView(
          title: "No Results Yet",
          message: "Add your first workout result for this exercise",
          systemImage: "chart.line.uptrend.xyaxis",
          action: { startNewResult() },
          actionLabel: "Add Result"
        )
      } else {
        List {
          Section {
            ForEach(displayedResults) { result in
              NavigationLink(destination: ExerciseResultEditView(result: result, isNew: false)) {
                HStack {
                  resultDisplay(for: result)
                  if result.id == bestResult?.id {
                    Text("PR")
                      .font(.caption2)
                      .fontWeight(.bold)
                      .foregroundStyle(.orange)
                  }
                  Spacer()
                  Text(result.date, format: .dateTime.day().month())
                    .foregroundStyle(.secondary)
                }
              }
            }
          } header: {
            if let oneRM = bestOneRepMax {
              Text("Estimated 1RM: \(Formatters.formatNumber(oneRM)) \(appSettings.weightUnit.rawValue)")
                .textCase(nil)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
          Picker("Sort", selection: $sortMode) {
            ForEach(SortMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)
          .padding(.vertical, 8)
          .background(.bar)
        }
      }
    }
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
        Button(action: { startNewResult() }) {
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
        try? modelContext.save()
      }
    }
    .sheet(isPresented: $showingNewResult, onDismiss: {
      newResult = nil
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
        Text(Formatters.formatTime(time))
      }
    case .weight:
      if let kg = result.weightKg {
        HStack(spacing: 4) {
          Text(Formatters.formatWeight(kg: kg, unit: appSettings.weightUnit))
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
      weightKg: 100,
      reps: 5
    )

    let result2 = ExerciseResult(
      exercise: exercise,
      date: .now.addingTimeInterval(-86400),
      weightKg: 95,
      reps: 1
    )

    self.insert(exercise)
    self.insert(result1)
    self.insert(result2)

    return exercise
  }
}
