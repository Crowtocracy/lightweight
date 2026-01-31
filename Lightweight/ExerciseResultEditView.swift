import SwiftUI
import SwiftData

struct ExerciseResultEditView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.appSettings) private var appSettings
  let result: ExerciseResult
  let isNew: Bool

  // Local state for editing
  @State private var localDate: Date
  @State private var localWeight: Int?
  @State private var localReps: Int?
  @State private var localNotes: String
  @State private var localOtherUnit: Double?

  // Local state for time input (using Strings for easier TextField binding)
  @State private var timeHours: String
  @State private var timeMinutes: String
  @State private var timeSeconds: String

  let commonReps = [1, 3, 5, 8, 10, 12]

  init(result: ExerciseResult, isNew: Bool) {
    self.result = result
    self.isNew = isNew

    // --- Initialize State ---
    // Use Date() for new results, otherwise the existing date
    _localDate = State(initialValue: isNew ? Date() : result.date)
    _localWeight = State(initialValue: result.weight)

    // Initialize reps to 1 for new weight-based exercises
    if isNew && result.exercise?.scoreType == .weight {
      _localReps = State(initialValue: 1)
    } else {
      _localReps = State(initialValue: result.reps)
    }

    _localNotes = State(initialValue: result.notes ?? "")
    _localOtherUnit = State(initialValue: result.otherUnit)

    // Time initialization
    if let time = result.time {
      let components = Formatters.timeIntervalToComponents(time)
      _timeHours = State(initialValue: "\(components.hours)")
      _timeMinutes = State(initialValue: String(format: "%02d", components.minutes))
      _timeSeconds = State(initialValue: String(format: "%02d", components.seconds))
    } else {
      _timeHours = State(initialValue: "0")
      _timeMinutes = State(initialValue: "00")
      _timeSeconds = State(initialValue: "00")
    }
  }


  // Helper to convert H, M, S strings back to TimeInterval
  private func calculateTimeInterval() -> TimeInterval? {
    guard let hours = Int(timeHours),
          let minutes = Int(timeMinutes),
          let seconds = Int(timeSeconds) else {
      // Handle invalid input - perhaps return nil or 0?
      // For simplicity, returning nil if any part is invalid non-numeric
      // Or return 0 if a partial time (like just seconds) is okay
      return nil // Or TimeInterval(0) if 0 is a valid "not set" state
    }

    // Basic validation
    if hours < 0 || minutes < 0 || minutes > 59 || seconds < 0 || seconds > 59 {
      return nil // Invalid time components
    }

    let totalSeconds = TimeInterval(hours * 3600 + minutes * 60 + seconds)
    return totalSeconds
  }

  private func handleSave() {
    saveChanges()
    if isNew {
      modelContext.insert(result)
    }
    HapticManager.success()
    dismiss()
  }

  private struct CustomSection<Content: View, Header: View>: View {
    let content: Content
    let header: Header

    init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
      self.content = content()
      self.header = header()
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        header
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
        VStack(spacing: 0) {
          content
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
      }
      .padding(.vertical, 8)
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {

          DatePicker(selection: $localDate, displayedComponents: [.date]) {
            Text("Date")
              .foregroundStyle(.secondary)
          }
          .padding()


        // --- Dynamic Sections Based on Score Type ---
        switch result.exercise?.scoreType {
        case .time:
          CustomSection {
            HStack(spacing: 5) {
              TextField("H", text: $timeHours)
                .keyboardType(.numberPad)
                .frame(maxWidth: 60)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              Text(":").font(.headline).foregroundColor(.secondary)
              TextField("M", text: $timeMinutes)
                .keyboardType(.numberPad)
                .frame(maxWidth: 60)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              Text(":").font(.headline).foregroundColor(.secondary)
              TextField("S", text: $timeSeconds)
                .keyboardType(.numberPad)
                .frame(maxWidth: 60)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              Spacer()
            }
          } header: {
            Text("Time")
          }

        case .weight:
          CustomSection {
            VStack(spacing: 16) {
              HStack {
                Text("Weight")
                  .foregroundStyle(.secondary)
                Spacer()
                TextField("Weight", value: $localWeight, format: .number)
                  .keyboardType(.decimalPad)
                  .multilineTextAlignment(.trailing)
                  .frame(maxWidth: 100)
                Text(appSettings.weightUnit.rawValue)
                  .foregroundStyle(.secondary)
              }

              HStack {
                Text("Reps")
                  .foregroundStyle(.secondary)
                Spacer()
                TextField("Reps", value: $localReps, format: .number)
                  .keyboardType(.numberPad)
                  .multilineTextAlignment(.trailing)
                  .frame(maxWidth: 100)
              }

              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                  ForEach(commonReps, id: \.self) { rep in
                    Button("\(rep)") {
                      HapticManager.selection()
                      localReps = rep
                      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                      to: nil, from: nil, for: nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(localReps == rep ? .accentColor : .secondary)
                  }
                }
              }
            }
          } header: {
            Text("Performance")
          }

        case .reps:
          CustomSection {
            VStack(spacing: 16) {
              HStack {
                Text("Reps")
                  .foregroundStyle(.secondary)
                Spacer()
                TextField("Reps", value: $localReps, format: .number)
                  .keyboardType(.numberPad)
                  .multilineTextAlignment(.trailing)
                  .frame(maxWidth: 100)
              }

              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                  ForEach(commonReps, id: \.self) { rep in
                    Button("\(rep)") {
                      HapticManager.selection()
                      localReps = rep
                      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                      to: nil, from: nil, for: nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(localReps == rep ? .accentColor : .secondary)
                  }
                }
              }
            }
          } header: {
            Text("Performance")
          }

        case .other:
          CustomSection {
            HStack {
              Text(result.exercise?.otherUnits ?? "Value")
                .foregroundStyle(.secondary)
              Spacer()
              TextField("Value", value: $localOtherUnit, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
            }
          } header: {
            Text("Performance")
          }

        case .none:
          EmptyView()
        }

        CustomSection {
          TextEditor(text: $localNotes)
            .frame(minHeight: 100)
            .font(.body)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .overlay {
              if localNotes.isEmpty {
                Text("Optional notes about the set...")
                  .foregroundColor(Color(uiColor: .placeholderText))
                  .padding(.leading, 4)
                  .padding(.top, 8)
                  .allowsHitTesting(false)
              }
            }
        } header: {
          Text("Notes")
        }

        if !isNew {
          CustomSection {
            Button(role: .destructive) {
              HapticManager.warning()
              modelContext.delete(result)
              dismiss()
            } label: {
              Text("Delete Result")
                .frame(maxWidth: .infinity, alignment: .center)
            }
          } header: {
            EmptyView()
          }
        }
      }
    }
    .background(Color(.systemBackground))
    .scrollDismissesKeyboard(.interactively)
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          handleSave()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isValid())
      }
    }
  }

  // --- Save Logic ---
  private func saveChanges() {
    result.date = localDate
    result.notes = localNotes.isEmpty ? nil : localNotes // Store nil if empty

    // Update based on score type
    switch result.exercise?.scoreType {
    case .time:
      result.time = calculateTimeInterval()
      // Clear other fields if they aren't relevant for time score
      result.weight = nil
      result.reps = nil
      result.otherUnit = nil
    case .weight:
      result.weight = localWeight
      result.reps = localReps
      // Clear others
      result.time = nil
      result.otherUnit = nil
    case .reps:
      result.reps = localReps
      // Clear others
      result.time = nil
      result.weight = nil
      result.otherUnit = nil
    case .other:
      result.otherUnit = localOtherUnit
      // Clear others
      result.time = nil
      result.weight = nil
      result.reps = nil
    case .none:
      // Clear all performance fields if score type is none
      result.time = nil
      result.weight = nil
      result.reps = nil
      result.otherUnit = nil
    }
  }

  // --- Validation Logic (Optional but Recommended) ---
  private func isValid() -> Bool {
    // Add checks here. E.g., ensure required fields are filled for the score type.
    switch result.exercise?.scoreType {
    case .time:
      // Check if time components parse correctly
      return calculateTimeInterval() != nil
    case .weight:
      // Weight and Reps are common, but maybe allow only weight? Check your logic.
      // For PRs, usually both are needed. Or at least weight.
      return localWeight != nil && localWeight ?? 0 > 0 && localReps != nil && localReps ?? 0 > 0
    case .reps:
      return localReps != nil && localReps ?? 0 > 0
    case .other:
      return localOtherUnit != nil && localOtherUnit ?? 0 > 0
    case .none:
      return true // No specific fields required
    }
  }
}
