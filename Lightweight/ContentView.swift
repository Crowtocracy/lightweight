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
  @State private var currentError: Error?
  @StateObject var appSettingsObject = AppSettings()

  var body: some View {
    ExerciseListView(searchText: $searchText, showingSettings: $showingSettings)
      .sheet(isPresented: $showingSettings) {
        SettingsView(appSettings: appSettingsObject)
      }
      .searchable(text: $searchText)
      .environment(\.appSettings, appSettingsObject)
      .errorAlert(error: $currentError)
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
  @State private var deleteError: Error?
  @StateObject private var viewModel = ExerciseListViewModel()

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
      Group {
        if exercises.isEmpty {
          EmptyStateView(
            title: "No Exercises Yet",
            message: "Add your first exercise to start tracking your workouts",
            systemImage: "figure.strengthtraining.traditional",
            action: { showingAddExercise = true },
            actionLabel: "Add Exercise"
          )
        } else {
          List {
            ForEach(exercises) { exercise in
              Button {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.2)) {
                  selectedExercise = exercise
                }
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
                  if let bestResult = viewModel.findBestResult(for: exercise) {
                    Text(viewModel.formatBestResult(result: bestResult, type: exercise.scoreType, weightUnit: appSettings.weightUnit))
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
        }
      }
      .navigationTitle("Lightweight")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $selectedExercise) { exercise in
        ExerciseResultsView(exercise: exercise)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Image("fox")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30)
            .onTapGesture {
              showingSettings = true
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
      .errorAlert(error: $deleteError)
    }
  }


  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      do {
        for index in offsets {
          modelContext.delete(exercises[index])
        }
        try modelContext.save()
        HapticManager.mediumImpact()
      } catch {
        deleteError = error
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(LightweightApp.DataController.previewContainer)
}
