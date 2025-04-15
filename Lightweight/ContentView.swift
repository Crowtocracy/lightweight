//
//  ContentView.swift
//  Lightweight
//
//  Created by Paul Brenner on 4/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @State var searchText: String = ""
  @State var showingSettings = false
  @StateObject var appSettingsObject = AppSettings()

  var body: some View {
    ExerciseListView(searchText: $searchText, showingSettings: $showingSettings)
      .confirmationDialog("Weight Units", isPresented: $showingSettings) {
        Button("Kilograms") {
          appSettingsObject.weightUnit = .kilograms
        }
        Button("Pounds") {
          appSettingsObject.weightUnit = .pounds
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("Select your preferred weight unit")
      }
      .searchable(text: $searchText)
      .environment(\.appSettings, appSettingsObject)
  }
}

struct ExerciseListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.appSettings) private var appSettings
  @Binding var searchText: String
  @Binding var showingSettings: Bool
  @Query private var exercises: [Exercise]
  @State private var selectedExercise: Exercise?
  @State private var showingAddExercise = false

  var execerciseDescriptor: FetchDescriptor<Exercise> {
    let searchPredicate: Predicate<Exercise> = #Predicate<Exercise> { entry in
      searchText.isEmpty ||
      entry.name.localizedStandardContains(searchText)
    }
    let sortDescriptor = SortDescriptor(\Exercise.name, order:   .forward)
    return FetchDescriptor<Exercise>(predicate: searchPredicate, sortBy: [sortDescriptor])
  }
  init(searchText: Binding<String>,
       showingSettings: Binding<Bool>) {
    self._searchText = searchText
    self._showingSettings = showingSettings

    _exercises = Query(execerciseDescriptor)
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(exercises) { exercise in
          Button {
            selectedExercise = exercise
          } label: {
            HStack {
              Text(exercise.name)
                .font(.headline)
                .foregroundColor(.primary)
              if let detail = exercise.detail {
                Text(detail)
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }

              Spacer()
              if let bestResult = findBestResult(for: exercise) {
                Text(formatBestResult(result: bestResult, type: exercise.scoreType))
                  .foregroundStyle(.secondary)
              }
            }
            .padding(.vertical, 8)
          }
          .listRowSeparator(.visible, edges: .bottom)
          .listRowBackground(Color(UIColor.systemBackground))
        }
        .onDelete(perform: deleteItems)
      }
      .listStyle(.plain)
      .background(Color(UIColor.systemBackground))
      .navigationTitle("Lightweight")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $selectedExercise) { exercise in
        ExerciseResultsView(exercise: exercise)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { showingSettings = true }) {
            Image("fox")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 22, height: 22)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showingAddExercise = true }) {
            Label("Add Item", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $showingAddExercise) {
        AddExerciseView()
      }
    }
  }

  private func findBestResult(for exercise: Exercise) -> ExerciseResult? {
    let results = exercise.results
    guard !results.isEmpty else { return nil }

    switch exercise.scoreType {
    case .weight:
      return results.max { a, b in
        (a.weight ?? 0) < (b.weight ?? 0)
      }
    case .reps:
      return results.max { a, b in
        (a.reps ?? 0) < (b.reps ?? 0)
      }
    case .time:
      return results.min { a, b in
        (a.time ?? 0) < (b.time ?? 0)
      }
    case .other:
      return results.max { a, b in
        (a.otherUnit ?? 0) < (b.otherUnit ?? 0)
      }
    }
  }

  private func formatBestResult(result: ExerciseResult, type: ScoreType) -> String {
    switch type {
    case .weight:
      guard let weight = result.weight else { return "" }
      let displayWeight = appSettings.weightUnit == .kilograms ? weight : Int(Double(weight) * 2.20462)
      if let reps = result.reps {
        return "\(displayWeight)\(appSettings.weightUnit.rawValue) × \(reps)"
      }
      return "\(displayWeight)\(appSettings.weightUnit.rawValue)"

    case .reps:
      guard let reps = result.reps else { return "" }
      return "\(reps)"

    case .time:
      guard let time = result.time else { return "" }
      let hours = Int(time) / 3600
      let minutes = Int(time) / 60 % 60
      let seconds = Int(time) % 60

      if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
      } else if minutes > 0 {
        return String(format: "%d:%02d", minutes, seconds)
      } else {
        return String(format: "%d\"", seconds)
      }

    case .other:
      guard let value = result.otherUnit else { return "" }
      return String(format: "%.3g", value)
    }
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(exercises[index])
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(LightweightApp.DataController.previewContainer)
}
