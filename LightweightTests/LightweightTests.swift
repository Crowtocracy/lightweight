import XCTest
import SwiftData
@testable import Lightweight

final class LightweightTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // Create an in-memory configuration for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Exercise.self, ExerciseResult.self, configurations: config)
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Exercise Tests

    func testCreateExercise() throws {
        let exercise = Exercise(name: "Bench Press", detail: "Barbell", scoreType: .weight)
        context.insert(exercise)

        let fetchDescriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(fetchDescriptor)

        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.name, "Bench Press")
        XCTAssertEqual(exercises.first?.detail, "Barbell")
        XCTAssertEqual(exercises.first?.scoreType, .weight)
        XCTAssertNotNil(exercises.first?.uuid)
        XCTAssertEqual(exercises.first?.results?.count, 0)
    }

    func testEditExercise() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)

        exercise.name = "Incline Bench Press"
        exercise.detail = "45 degrees"
        exercise.scoreType = .reps

        let fetchDescriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(fetchDescriptor)

        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.name, "Incline Bench Press")
        XCTAssertEqual(exercises.first?.detail, "45 degrees")
        XCTAssertEqual(exercises.first?.scoreType, .reps)
    }

    func testDeleteExercise() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        context.delete(exercise)

        let fetchDescriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(fetchDescriptor)

        XCTAssertEqual(exercises.count, 0)
    }

    // MARK: - Exercise Result Tests

    func testCreateExerciseResult() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)

        let result = ExerciseResult(
            exercise: exercise,
            date: Date(),
            notes: "Good form",
            weightKg: 100,
            reps: 5
        )
        context.insert(result)

        XCTAssertEqual(exercise.results?.count, 1)
        XCTAssertEqual(exercise.results?.first?.weightKg, 100)
        XCTAssertEqual(exercise.results?.first?.reps, 5)
        XCTAssertEqual(exercise.results?.first?.notes, "Good form")
        XCTAssertEqual(result.exercise?.name, "Bench Press")
    }

    func testEditExerciseResult() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)

        let result = ExerciseResult(exercise: exercise, weightKg: 100, reps: 5)
        context.insert(result)

        result.weightKg = 105
        result.reps = 3
        result.notes = "PR attempt"

        let fetchDescriptor = FetchDescriptor<ExerciseResult>()
        let results = try context.fetch(fetchDescriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.weightKg, 105)
        XCTAssertEqual(results.first?.reps, 3)
        XCTAssertEqual(results.first?.notes, "PR attempt")
    }

    func testDeleteExerciseResult() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)

        let result = ExerciseResult(exercise: exercise, weightKg: 100, reps: 5)
        context.insert(result)
        XCTAssertEqual(exercise.results?.count, 1)

        context.delete(result)
        XCTAssertEqual(exercise.results?.count, 0)

        let fetchDescriptor = FetchDescriptor<ExerciseResult>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 0)
    }

    func testCascadeDeletion() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)

        let result1 = ExerciseResult(exercise: exercise, weightKg: 100, reps: 5)
        let result2 = ExerciseResult(exercise: exercise, weightKg: 105, reps: 3)
        context.insert(result1)
        context.insert(result2)
        XCTAssertEqual(exercise.results?.count, 2)

        context.delete(exercise)

        let fetchDescriptor = FetchDescriptor<ExerciseResult>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - One Rep Max

    func testOneRepMaxSingleRep() {
        XCTAssertEqual(OneRepMax.epley(weight: 100, reps: 1), 100)
    }

    func testOneRepMaxMultipleReps() throws {
        let estimate = try XCTUnwrap(OneRepMax.epley(weight: 100, reps: 5))
        // Epley: 100 * (1 + 5/30) = 116.666...
        XCTAssertEqual(estimate, 116.6667, accuracy: 0.001)
    }

    func testOneRepMaxInvalidInputs() {
        XCTAssertNil(OneRepMax.epley(weight: 0, reps: 5))
        XCTAssertNil(OneRepMax.epley(weight: 100, reps: 0))
    }

    // MARK: - Weight Conversion

    func testWeightConversionRoundTrip() {
        let kg = 62.5
        let pounds = WeightUnit.pounds.fromKilograms(kg)
        let backToKg = WeightUnit.pounds.toKilograms(pounds)
        XCTAssertEqual(backToKg, kg, accuracy: 0.0001)
    }

    func testKilogramsAreCanonical() {
        XCTAssertEqual(WeightUnit.kilograms.fromKilograms(100), 100)
        XCTAssertEqual(WeightUnit.kilograms.toKilograms(100), 100)
    }

    // MARK: - Number Formatting

    func testFormatNumberDropsTrailingZeros() {
        XCTAssertEqual(Formatters.formatNumber(100.0), "100")
        XCTAssertEqual(Formatters.formatNumber(62.5), "62.5")
        XCTAssertEqual(Formatters.formatNumber(62.53), "62.53")
    }

    // MARK: - Best Result Selection

    @MainActor
    func testBestWeightResultUsesEstimatedOneRepMax() {
        let viewModel = ExerciseListViewModel()
        let exercise = Exercise(name: "Squat", scoreType: .weight)
        context.insert(exercise)

        // 100kg x 5 -> ~116.7 1RM beats a heavier single of 110kg x 1.
        let volume = ExerciseResult(exercise: exercise, weightKg: 100, reps: 5)
        let single = ExerciseResult(exercise: exercise, weightKg: 110, reps: 1)
        context.insert(volume)
        context.insert(single)

        XCTAssertEqual(viewModel.findBestResult(for: exercise)?.weightKg, 100)
    }

    // MARK: - Export / Import Round Trip

    @MainActor
    func testExportImportRoundTrip() throws {
        let exercise = Exercise(name: "Deadlift", scoreType: .weight)
        context.insert(exercise)
        context.insert(ExerciseResult(exercise: exercise, date: Date(), weightKg: 140, reps: 3))
        try context.save()

        let exporter = DataExporter(modelContext: context)
        let url = try XCTUnwrap(exporter.exportData(format: .json))

        // Wipe everything to simulate a fresh install / data loss.
        try context.delete(model: Exercise.self)
        try context.delete(model: ExerciseResult.self)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Exercise>()).count, 0)

        let importer = DataImporter(modelContext: context)
        let summary = try importer.importBackup(from: url)
        XCTAssertEqual(summary.exercisesAdded, 1)
        XCTAssertEqual(summary.resultsAdded, 1)

        let restored = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(restored.first?.name, "Deadlift")
        XCTAssertEqual(restored.first?.results?.first?.weightKg, 140)
        XCTAssertEqual(restored.first?.results?.first?.reps, 3)
    }

    @MainActor
    func testImportDeduplicates() throws {
        let exercise = Exercise(name: "Deadlift", scoreType: .weight)
        context.insert(exercise)
        context.insert(ExerciseResult(exercise: exercise, date: Date(), weightKg: 140, reps: 3))
        try context.save()

        let exporter = DataExporter(modelContext: context)
        let url = try XCTUnwrap(exporter.exportData(format: .json))

        // Importing back into a store that already has the data adds nothing.
        let importer = DataImporter(modelContext: context)
        let summary = try importer.importBackup(from: url)
        XCTAssertEqual(summary.exercisesAdded, 0)
        XCTAssertEqual(summary.resultsAdded, 0)
        XCTAssertEqual(summary.resultsSkipped, 1)
    }
}
