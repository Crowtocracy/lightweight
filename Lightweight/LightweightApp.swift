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
  /// CloudKit container that backs iCloud sync. Must be owned by the app's
  /// development team; keep this in sync with the value in the entitlements.
  static let cloudKitContainerID = "iCloud.com.crowtocracy.Lightweight"

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Exercise.self, ExerciseResult.self
    ])

    // Primary configuration: SwiftData mirrored to the app's private CloudKit
    // database, so data is backed up to iCloud and synced across the user's
    // devices automatically.
    let cloudConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      cloudKitDatabase: .private(LightweightApp.cloudKitContainerID)
    )

    if let container = try? ModelContainer(for: schema, configurations: [cloudConfiguration]) {
      return container
    }

    // Fallback: if CloudKit can't be initialised (e.g. entitlement or
    // provisioning issue, or the user has no iCloud account), keep working with
    // an on-device store instead of crashing and losing access to the data.
    let localConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      cloudKitDatabase: .none
    )
    do {
      return try ModelContainer(for: schema, configurations: [localConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          FirstLaunchManager.prepareStore(container: sharedModelContainer)
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
          weightKg: 100,
          reps: 5
        )
        container.mainContext.insert(result1)

        let result2 = ExerciseResult(
          exercise: backSquat,
          date: Date().addingTimeInterval(-86400), // Yesterday
          weightKg: 95,
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

// First Launch Manager to handle initial data setup and lightweight migrations.
@MainActor
class FirstLaunchManager {
  private static let wasLaunchedBefore = "wasLaunchedBefore"

  /// Run once per launch: migrate any legacy data, then seed sample data on a
  /// genuinely fresh install.
  static func prepareStore(container: ModelContainer) {
    let context = container.mainContext
    migrateLegacyWeights(context: context)

    let defaults = UserDefaults.standard
    guard !defaults.bool(forKey: wasLaunchedBefore) else { return }

    // Only seed when the store is empty. A device restoring from iCloud might
    // not have synced yet, but this still prevents the common case of a
    // reinstall duplicating the sample exercises against already-synced data.
    let existingCount = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
    if existingCount == 0 {
      setupInitialData(context: context)
    }
    defaults.set(true, forKey: wasLaunchedBefore)
  }

  /// Backfill `weightKg` from the legacy integer `weight` field. Legacy values
  /// were treated as kilograms by the display code, so we carry that forward.
  private static func migrateLegacyWeights(context: ModelContext) {
    let descriptor = FetchDescriptor<ExerciseResult>(
      predicate: #Predicate<ExerciseResult> { $0.weightKg == nil && $0.weight != nil }
    )
    guard let legacyResults = try? context.fetch(descriptor), !legacyResults.isEmpty else { return }
    for result in legacyResults {
      if let oldWeight = result.weight {
        result.weightKg = Double(oldWeight)
      }
    }
    try? context.save()
  }

  private static func setupInitialData(context: ModelContext) {
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
      weightKg: 60,
      reps: 5
    )
    context.insert(sampleResult)
    try? context.save()
  }
}
