//
//  SettingsView.swift
//  Lightweight
//
//  Settings screen for app configuration
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var appSettings: AppSettings
    @StateObject private var cloudStatus = CloudKitStatusManager()
    @State private var showingExportOptions = false
    @State private var exportURL: IdentifiableURL?
    @State private var showingResetConfirmation = false
    @State private var showingImporter = false
    @State private var importMessage: String?
    @State private var importError: Error?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Backup / Sync Section
                Section {
                    HStack {
                        Label("iCloud Sync", systemImage: cloudStatus.status.symbol)
                        Spacer()
                        Text(cloudStatus.status.label)
                            .foregroundStyle(cloudStatus.status.isHealthy ? Color.green : Color.secondary)
                    }
                    if let advice = cloudStatus.status.advice {
                        Text(advice)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("When sync is on, your workouts are backed up to iCloud and kept up to date across your devices.")
                }

                // MARK: - Units Section
                Section {
                    Picker("Weight Unit", selection: $appSettings.weightUnit) {
                        ForEach([WeightUnit.kilograms, .pounds], id: \.self) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                } header: {
                    Text("Units")
                } footer: {
                    Text("Weights are stored the same way regardless of unit, so switching never changes your saved numbers.")
                }

                // MARK: - Data Management Section
                Section {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }

                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export a backup, restore from one, or reset the app to its initial state.")
                }

                // MARK: - About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/crowtocracy/lightweight")!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Export Format", isPresented: $showingExportOptions) {
                Button("Export as JSON") {
                    exportData(format: .json)
                }
                Button("Export as CSV") {
                    exportData(format: .csv)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose export format for your workout data")
            }
            .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all exercises and workout data. This action cannot be undone.")
            }
            .sheet(item: $exportURL) { identifiableURL in
                ShareSheet(url: identifiableURL.url)
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import Complete", isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )) {
                Button("OK") { importMessage = nil }
            } message: {
                Text(importMessage ?? "")
            }
            .errorAlert(error: $importError)
            .onAppear {
                cloudStatus.refresh()
            }
        }
    }

    private func exportData(format: ExportFormat) {
        let exporter = DataExporter(modelContext: modelContext)
        if let url = exporter.exportData(format: format) {
            exportURL = IdentifiableURL(url: url)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let importer = DataImporter(modelContext: modelContext)
                let summary = try importer.importBackup(from: url)
                importMessage = "Added \(summary.exercisesAdded) exercise(s) and \(summary.resultsAdded) result(s). Skipped \(summary.resultsSkipped) duplicate(s)."
                HapticManager.success()
            } catch {
                importError = error
                HapticManager.error()
            }
        case .failure(let error):
            importError = error
        }
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: Exercise.self)
            try modelContext.delete(model: ExerciseResult.self)
            try modelContext.save()

            // Reset first launch flag to show sample data again
            UserDefaults.standard.removeObject(forKey: "wasLaunchedBefore")

            // Recreate sample data
            FirstLaunchManager.prepareStore(container: modelContext.container)
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL

    init(url: URL) {
        self.url = url
    }
}
