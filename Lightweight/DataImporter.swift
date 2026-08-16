//
//  DataImporter.swift
//  Lightweight
//
//  Restore workout data from a previously exported JSON backup. Complements
//  DataExporter so a backup is a real safety net, not a one-way export.
//

import Foundation
import SwiftData

@MainActor
final class DataImporter {
    struct Summary {
        let exercisesAdded: Int
        let resultsAdded: Int
        let resultsSkipped: Int
    }

    enum ImportError: LocalizedError {
        case unreadable
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "Couldn't read the selected file."
            case .invalidFormat:
                return "This file isn't a Lightweight backup, or it's in an unsupported format."
            }
        }
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Import (merge) a backup file, returning what changed. Existing exercises
    /// are matched by name and existing results are de-duplicated, so importing
    /// the same backup twice is safe.
    func importBackup(from url: URL) throws -> Summary {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.unreadable
        }
        let backupExercises = try decode(data)
        return merge(backupExercises)
    }

    private func decode(_ data: Data) throws -> [BackupExercise] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let backup = try? decoder.decode(WorkoutBackup.self, from: data) {
            return backup.exercises
        }

        // Fall back to the legacy v1 array-of-exercises format.
        if let legacy = try? decoder.decode([LegacyBackupExercise].self, from: data) {
            return legacy.map { legacyExercise in
                BackupExercise(
                    name: legacyExercise.name,
                    detail: legacyExercise.detail,
                    scoreType: legacyExercise.scoreType ?? ScoreType.weight.rawValue,
                    otherUnits: legacyExercise.otherUnits,
                    results: (legacyExercise.results ?? []).map { legacyResult in
                        BackupResult(
                            date: legacyResult.date ?? Date(),
                            notes: legacyResult.notes,
                            weightKg: legacyResult.weight.map(Double.init),
                            reps: legacyResult.reps,
                            time: legacyResult.time,
                            otherUnit: legacyResult.otherUnit
                        )
                    }
                )
            }
        }

        throw ImportError.invalidFormat
    }

    private func merge(_ backupExercises: [BackupExercise]) -> Summary {
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        var byName: [String: Exercise] = [:]
        for exercise in existing {
            byName[exercise.name.lowercased()] = exercise
        }

        var exercisesAdded = 0
        var resultsAdded = 0
        var resultsSkipped = 0

        for backupExercise in backupExercises {
            let key = backupExercise.name.lowercased()
            let exercise: Exercise
            if let match = byName[key] {
                exercise = match
            } else {
                exercise = Exercise(
                    name: backupExercise.name,
                    detail: backupExercise.detail,
                    scoreType: ScoreType(rawValue: backupExercise.scoreType) ?? .weight,
                    otherUnits: backupExercise.otherUnits
                )
                modelContext.insert(exercise)
                byName[key] = exercise
                exercisesAdded += 1
            }

            let existingResults = exercise.results ?? []
            for backupResult in backupExercise.results {
                if existingResults.contains(where: { isSameResult($0, backupResult) }) {
                    resultsSkipped += 1
                    continue
                }
                let result = ExerciseResult(
                    exercise: exercise,
                    date: backupResult.date,
                    notes: backupResult.notes,
                    weightKg: backupResult.weightKg,
                    reps: backupResult.reps,
                    time: backupResult.time,
                    otherUnit: backupResult.otherUnit
                )
                modelContext.insert(result)
                resultsAdded += 1
            }
        }

        try? modelContext.save()
        return Summary(
            exercisesAdded: exercisesAdded,
            resultsAdded: resultsAdded,
            resultsSkipped: resultsSkipped
        )
    }

    private func isSameResult(_ existing: ExerciseResult, _ backup: BackupResult) -> Bool {
        abs(existing.date.timeIntervalSince(backup.date)) < 1 &&
        existing.weightKg == backup.weightKg &&
        existing.reps == backup.reps &&
        existing.time == backup.time &&
        existing.otherUnit == backup.otherUnit
    }
}
