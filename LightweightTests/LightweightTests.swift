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
        // Create and insert exercise
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        // Edit exercise
        exercise.name = "Incline Bench Press"
        exercise.detail = "45 degrees"
        exercise.scoreType = .reps
        
        // Fetch and verify
        let fetchDescriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.name, "Incline Bench Press")
        XCTAssertEqual(exercises.first?.detail, "45 degrees")
        XCTAssertEqual(exercises.first?.scoreType, .reps)
    }
    
    func testDeleteExercise() throws {
        // Create and insert exercise
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        // Delete exercise
        context.delete(exercise)
        
        // Verify deletion
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
            weight: 225,
            reps: 5
        )
        context.insert(result)
        
        // Verify exercise has the result
        XCTAssertEqual(exercise.results?.count, 1)
        XCTAssertEqual(exercise.results?.first?.weight, 225)
        XCTAssertEqual(exercise.results?.first?.reps, 5)
        XCTAssertEqual(exercise.results?.first?.notes, "Good form")
        
        // Verify result is properly linked to exercise
        XCTAssertEqual(result.exercise?.name, "Bench Press")
    }
    
    func testEditExerciseResult() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        let result = ExerciseResult(
            exercise: exercise,
            weight: 225,
            reps: 5
        )
        context.insert(result)
        
        // Edit result
        result.weight = 235
        result.reps = 3
        result.notes = "PR attempt"
        
        // Verify changes
        let fetchDescriptor = FetchDescriptor<ExerciseResult>()
        let results = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.weight, 235)
        XCTAssertEqual(results.first?.reps, 3)
        XCTAssertEqual(results.first?.notes, "PR attempt")
    }
    
    func testDeleteExerciseResult() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        let result = ExerciseResult(
            exercise: exercise,
            weight: 225,
            reps: 5
        )
        context.insert(result)
        
        // Verify initial state
        XCTAssertEqual(exercise.results?.count, 1)
        
        // Delete result
        context.delete(result)
        
        // Verify deletion
        XCTAssertEqual(exercise.results?.count, 0)
        
        let fetchDescriptor = FetchDescriptor<ExerciseResult>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 0)
    }
    
    func testCascadeDeletion() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        let result1 = ExerciseResult(exercise: exercise, weight: 225, reps: 5)
        let result2 = ExerciseResult(exercise: exercise, weight: 235, reps: 3)
        context.insert(result1)
        context.insert(result2)
        
        // Verify initial state
        XCTAssertEqual(exercise.results?.count, 2)
        
        // Delete exercise
        context.delete(exercise)
        
        // Verify all results are deleted
        let fetchDescriptor = FetchDescriptor<ExerciseResult>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 0)
    }
}