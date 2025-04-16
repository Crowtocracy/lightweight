//
//  LightweightApp.swift
//  Lightweight
//
//  Created by Paul Brenner on 4/15/25.
//

import SwiftUI
import SwiftData

@main
struct LightweightApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Exercise.self,ExerciseResult.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          FirstLaunchManager.checkAndSetupInitialData(container: sharedModelContainer)
        }
    }
    .modelContainer(sharedModelContainer)
  }

  @MainActor
  class DataController {
    static let previewContainer: ModelContainer = {
      do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, configurations: config)

        let backSquat = Exercise(name: "Back Squat", scoreType: .weight)
        container.mainContext.insert(backSquat)

        // Add some sample results
        let result1 = ExerciseResult(
          exercise: backSquat,
          date: Date(),
          notes: "Felt strong",
          weight: 225,
          reps: 5
        )
        container.mainContext.insert(result1)

        let result2 = ExerciseResult(
          exercise: backSquat,
          date: Date().addingTimeInterval(-86400), // Yesterday
          weight: 215,
          reps: 5
        )
        container.mainContext.insert(result2)

        return container
      } catch {
        fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
      }
    }()
  }
}

// First Launch Manager to handle initial data setup
@MainActor
class FirstLaunchManager {
  private static let wasLaunchedBefore = "wasLaunchedBefore"

  static func checkAndSetupInitialData(container: ModelContainer) {
    let defaults = UserDefaults.standard

    if !defaults.bool(forKey: wasLaunchedBefore) {
      setupInitialData(container: container)
      defaults.set(true, forKey: wasLaunchedBefore)
    }
  }

  private static func setupInitialData(container: ModelContainer) {
    let context = container.mainContext

    // Sample exercises
    let backSquat = Exercise(
      name: "Back Squat",
      scoreType: .weight
    )

    let snatch = Exercise(
      name: "Power Snatch",
      scoreType: .weight
    )

    let bike = Exercise(
      name: "Assault Bike",
      detail: "10 minutes",
      scoreType: .other,
      otherUnits: "calories"
    )

    let sample = Exercise(
      name: "Sample Exercises",
      detail: "Slide to delete",
      scoreType: .weight
    )

    let exercises = [backSquat, snatch, bike, sample]
    exercises.forEach { context.insert($0) }

    // Add a sample result for back squat
    let sampleResult = ExerciseResult(
      exercise: backSquat,
      date: Date(),
      notes: "First workout - feeling good!",
      weight: 135,
      reps: 5
    )
    context.insert(sampleResult)
  }
}
