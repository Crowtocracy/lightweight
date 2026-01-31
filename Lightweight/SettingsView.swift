//
//  SettingsView.swift
//  Lightweight
//
//  Settings screen for app configuration
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var appSettings: AppSettings
    @State private var showingExportOptions = false
    @State private var exportURL: IdentifiableURL?
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
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
                    Text("Choose your preferred weight measurement unit")
                }
                
                // MARK: - Data Management Section
                Section {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
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
                    Text("Export your workout data or reset the app to its initial state")
                }
                
                // MARK: - About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourusername/lightweight")!) {
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
        }
    }
    
    private func exportData(format: ExportFormat) {
        let exporter = DataExporter(modelContext: modelContext)
        if let url = exporter.exportData(format: format) {
            exportURL = IdentifiableURL(url: url)
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
            FirstLaunchManager.checkAndSetupInitialData(container: modelContext.container)
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