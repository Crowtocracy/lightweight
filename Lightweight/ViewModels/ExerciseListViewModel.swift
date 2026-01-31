//
//  ExerciseListViewModel.swift
//  Lightweight
//
//  View model for exercise list logic
//

import Foundation
import SwiftData

@MainActor
class ExerciseListViewModel: ObservableObject {
    
    func findBestResult(for exercise: Exercise) -> ExerciseResult? {
        guard let results = exercise.results, !results.isEmpty else { return nil }
        
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
    
    func formatBestResult(result: ExerciseResult, type: ScoreType, weightUnit: WeightUnit) -> String {
        switch type {
        case .weight:
            guard let weight = result.weight else { return "" }
            return Formatters.formatWeightWithReps(weight, reps: result.reps, unit: weightUnit)
            
        case .reps:
            guard let reps = result.reps else { return "" }
            return "\(reps)"
            
        case .time:
            guard let time = result.time else { return "" }
            return Formatters.formatTime(time)
            
        case .other:
            guard let value = result.otherUnit else { return "" }
            return Formatters.formatDouble(value)
        }
    }
}