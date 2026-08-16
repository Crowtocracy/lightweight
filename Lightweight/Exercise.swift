//
//  Exercise.swift
//  Lightweight
//
//  Created by Paul Brenner on 4/15/25.
//

import Foundation
import SwiftData

@Model
final class Exercise {
  var uuid: UUID = UUID()
  var name: String = ""
  var detail: String?
  var scoreType: ScoreType = ScoreType.weight
  var otherUnits: String?
  @Relationship(deleteRule: .cascade) var results: [ExerciseResult]? = []

  init(name: String, detail: String? = nil, scoreType: ScoreType = .weight, otherUnits: String? = nil) {
    self.uuid = UUID()
    self.name = name
    self.detail = detail
    self.scoreType = scoreType
    self.otherUnits = otherUnits
    self.results = []
  }
}

@Model
final class ExerciseResult {
  var id: UUID = UUID()
  var date: Date = Date()
  var notes: String?

  /// Legacy integer weight, retained only so older data can be migrated into
  /// `weightKg`. Do not read or write this from app code — use `weightKg`.
  var weight: Int?

  /// Canonical weight, always stored in kilograms. Nil for non-weight results.
  /// Display/entry in pounds is converted at the UI layer; the stored value is
  /// always kg so switching units never mutates saved data.
  var weightKg: Double?

  var reps: Int?
  var time: TimeInterval?
  var otherUnit: Double?

  @Relationship(inverse: \Exercise.results) var exercise: Exercise?

  init(
    exercise: Exercise? = nil,
    date: Date = Date(),
    notes: String? = nil,
    weightKg: Double? = nil,
    reps: Int? = nil,
    time: TimeInterval? = nil,
    otherUnit: Double? = nil
  ) {
    self.id = UUID()
    self.exercise = exercise
    self.date = date
    self.notes = notes
    self.weightKg = weightKg
    self.reps = reps
    self.time = time
    self.otherUnit = otherUnit
  }
}

enum ScoreType: String, Codable, CaseIterable {
  case time
  case weight
  case reps
  case other
}
