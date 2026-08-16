//
//  DataExporter.swift
//  Lightweight
//
//  Export workout data to various formats
//

import Foundation
import SwiftData

enum ExportFormat {
    case json
    case csv
}

@MainActor
class DataExporter {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportData(format: ExportFormat) -> URL? {
        switch format {
        case .json:
            return exportAsJSON()
        case .csv:
            return exportAsCSV()
        }
    }

    private func exportAsJSON() -> URL? {
        do {
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())

            let backup = WorkoutBackup(
                version: WorkoutBackup.currentVersion,
                exportedAt: Date(),
                exercises: exercises.map { exercise in
                    BackupExercise(
                        name: exercise.name,
                        detail: exercise.detail,
                        scoreType: exercise.scoreType.rawValue,
                        otherUnits: exercise.otherUnits,
                        results: (exercise.results ?? []).map { result in
                            BackupResult(
                                date: result.date,
                                notes: result.notes,
                                weightKg: result.weightKg,
                                reps: result.reps,
                                time: result.time,
                                otherUnit: result.otherUnit
                            )
                        }
                    )
                }
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(backup)
            return saveToFile(data: jsonData, fileName: "lightweight_export.json")
        } catch {
            print("JSON export failed: \(error)")
            return nil
        }
    }

    private func exportAsCSV() -> URL? {
        do {
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            let dateFormatter = ISO8601DateFormatter()

            var csvString = "Exercise,Detail,Score Type,Date,Weight (kg),Reps,Time,Other Value,Notes\n"

            for exercise in exercises {
                for result in exercise.results ?? [] {
                    let row = [
                        exercise.name,
                        exercise.detail ?? "",
                        exercise.scoreType.rawValue,
                        dateFormatter.string(from: result.date),
                        result.weightKg.map { Formatters.formatNumber($0) } ?? "",
                        result.reps?.description ?? "",
                        result.time?.description ?? "",
                        result.otherUnit?.description ?? "",
                        result.notes ?? ""
                    ]
                    .map { field in
                        // Escape quotes and wrap in quotes if contains comma
                        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                        return field.contains(",") || field.contains("\"") || field.contains("\n")
                            ? "\"\(escaped)\""
                            : escaped
                    }
                    .joined(separator: ",")

                    csvString += row + "\n"
                }
            }

            guard let data = csvString.data(using: .utf8) else { return nil }
            return saveToFile(data: data, fileName: "lightweight_export.csv")
        } catch {
            print("CSV export failed: \(error)")
            return nil
        }
    }

    private func saveToFile(data: Data, fileName: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save file: \(error)")
            return nil
        }
    }
}
