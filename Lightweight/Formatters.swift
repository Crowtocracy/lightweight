//
//  Formatters.swift
//  Lightweight
//
//  Centralized formatting utilities
//

import Foundation

enum Formatters {
    
    // MARK: - Time Formatting
    
    static func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else if milliseconds > 0 && totalSeconds == 0 {
            return String(format: "%d.%03d", seconds, milliseconds)
        } else {
            return String(format: "%d\"", seconds)
        }
    }
    
    static func timeIntervalToComponents(_ time: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int, milliseconds: Int) {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return (hours, minutes, seconds, milliseconds)
    }
    
    // MARK: - Weight Formatting

    /// Format a canonical kilogram value for display in the user's chosen unit.
    static func formatWeight(kg: Double, unit: WeightUnit) -> String {
        let displayValue = unit.fromKilograms(kg)
        return "\(formatNumber(displayValue)) \(unit.rawValue)"
    }

    /// Format a weight (kg) with its rep count, e.g. "62.5kg × 5".
    static func formatWeightWithReps(kg: Double, reps: Int?, unit: WeightUnit) -> String {
        let displayValue = unit.fromKilograms(kg)
        if let reps = reps {
            return "\(formatNumber(displayValue))\(unit.rawValue) × \(reps)"
        }
        return "\(formatNumber(displayValue))\(unit.rawValue)"
    }

    // MARK: - Number Formatting

    /// Format a Double without a trailing ".0", keeping up to two decimals.
    static func formatNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        var formatted = String(format: "%.2f", value)
        while formatted.hasSuffix("0") { formatted.removeLast() }
        return formatted
    }

    static func formatDouble(_ value: Double, units: String? = nil) -> String {
        let formattedValue = String(format: "%.3g", value)
        if let units = units?.lowercased() {
            return "\(formattedValue) \(units)"
        }
        return formattedValue
    }
}