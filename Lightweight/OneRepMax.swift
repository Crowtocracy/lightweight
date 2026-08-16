//
//  OneRepMax.swift
//  Lightweight
//
//  Estimated one-rep-max calculation. This is the core metric for a PR /
//  1RM tracker: it lets sets performed at different rep counts be compared
//  on a single scale, so "the best set" reflects real strength rather than
//  just the heaviest load logged.
//

import Foundation

enum OneRepMax {

    /// Estimated 1RM in the same unit as `weight`, using the Epley formula.
    /// A single rep returns the weight unchanged. Returns nil when the inputs
    /// can't produce a meaningful estimate.
    static func epley(weight: Double, reps: Int) -> Double? {
        guard weight > 0, reps >= 1 else { return nil }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Convenience for an `ExerciseResult`: estimated 1RM in kilograms.
    static func estimatedKg(for result: ExerciseResult) -> Double? {
        guard let kg = result.weightKg else { return nil }
        return epley(weight: kg, reps: result.reps ?? 1)
    }
}
