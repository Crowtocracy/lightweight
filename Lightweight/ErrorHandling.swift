//
//  ErrorHandling.swift
//  Lightweight
//
//  Error handling utilities and alerts
//

import SwiftUI

struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

enum DataError: LocalizedError {
    case saveFailed
    case deleteFailed
    case fetchFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save changes. Please try again."
        case .deleteFailed:
            return "Failed to delete item. Please try again."
        case .fetchFailed:
            return "Failed to load data. Please restart the app."
        case .invalidData:
            return "Invalid data provided. Please check your input."
        }
    }
}