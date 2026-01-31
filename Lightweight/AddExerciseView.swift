import SwiftUI
import SwiftData

struct AddExerciseView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  
  @State private var name: String = ""
  @State private var detail: String = ""
  @State private var scoreType: ScoreType = .weight
  @State private var otherUnits: String = ""
  @State private var saveError: Error?
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Exercise Name", text: $name)
          TextField("Detail (optional)", text: $detail)
        }
        
        Section {
          Picker("Score Type", selection: $scoreType) {
            Text("Weight").tag(ScoreType.weight)
            Text("Reps").tag(ScoreType.reps)
            Text("Time").tag(ScoreType.time)
            Text("Other").tag(ScoreType.other)
          }
          
          if scoreType == .other {
            TextField("Units", text: $otherUnits)
          }
        }
      }
      .navigationTitle("New Exercise")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            HapticManager.lightImpact()
            saveExercise()
          }
          .disabled(name.isEmpty || (scoreType == .other && otherUnits.isEmpty))
        }
      }
      .errorAlert(error: $saveError)
    }
  }
  
  private func saveExercise() {
    do {
      let exercise = Exercise(
        name: name,
        detail: detail.isEmpty ? nil : detail,
        scoreType: scoreType,
        otherUnits: scoreType == .other ? otherUnits : nil
      )
      modelContext.insert(exercise)
      try modelContext.save()
      HapticManager.success()
      dismiss()
    } catch {
      HapticManager.error()
      saveError = error
    }
  }
}

#Preview {
  AddExerciseView()
    .modelContainer(LightweightApp.DataController.previewContainer)
}