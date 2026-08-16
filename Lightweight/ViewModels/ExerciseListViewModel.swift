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
            // "Best" is the highest estimated 1RM, so a heavy single and a
            // lighter set for many reps are compared fairly.
            return results
                .filter { $0.weightKg != nil }
                .max { (OneRepMax.estimatedKg(for: $0) ?? 0) < (OneRepMax.estimatedKg(for: $1) ?? 0) }
        case .reps:
            return results
                .filter { $0.reps != nil }
                .max { ($0.reps ?? 0) < ($1.reps ?? 0) }
        case .time:
            // Fastest (smallest) time wins; ignore results with no time recorded
            // so a missing value can't masquerade as the best.
            return results
                .filter { $0.time != nil }
                .min { ($0.time ?? 0) < ($1.time ?? 0) }
        case .other:
            return results
                .filter { $0.otherUnit != nil }
                .max { ($0.otherUnit ?? 0) < ($1.otherUnit ?? 0) }
        }
    }

    func formatBestResult(result: ExerciseResult, type: ScoreType, weightUnit: WeightUnit) -> String {
        switch type {
        case .weight:
            guard let kg = result.weightKg else { return "" }
            return Formatters.formatWeightWithReps(kg: kg, reps: result.reps, unit: weightUnit)

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