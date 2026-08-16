//
//  WorkoutBackup.swift
//  Lightweight
//
//  Codable representation of the full workout history, used for JSON export and
//  import. Keeping this a typed, versioned format makes backups round-trippable
//  so exported data can actually be restored.
//

import Foundation

struct WorkoutBackup: Codable {
  var version: Int
  var exportedAt: Date
  var exercises: [BackupExercise]

  static let currentVersion = 2
}

struct BackupExercise: Codable {
  var name: String
  var detail: String?
  var scoreType: String
  var otherUnits: String?
  var results: [BackupResult]
}

struct BackupResult: Codable {
  var date: Date
  var notes: String?
  var weightKg: Double?
  var reps: Int?
  var time: TimeInterval?
  var otherUnit: Double?
}

// MARK: - Legacy (v1) format

/// The original export was a bare array of exercises whose results stored an
/// integer `weight`. Decoded as a fallback so old backups remain restorable.
struct LegacyBackupExercise: Codable {
  var name: String
  var detail: String?
  var scoreType: String?
  var otherUnits: String?
  var results: [LegacyBackupResult]?
}

struct LegacyBackupResult: Codable {
  var date: Date?
  var notes: String?
  var weight: Int?
  var reps: Int?
  var time: TimeInterval?
  var otherUnit: Double?
}
