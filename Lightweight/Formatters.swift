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
    
    static func formatWeight(_ weight: Int, unit: WeightUnit) -> String {
        let displayWeight = unit == .kilograms ? weight : Int(Double(weight) * 2.20462)
        return "\(displayWeight) \(unit.rawValue)"
    }
    
    static func formatWeightWithReps(_ weight: Int, reps: Int?, unit: WeightUnit) -> String {
        let displayWeight = unit == .kilograms ? weight : Int(Double(weight) * 2.20462)
        if let reps = reps {
            return "\(displayWeight)\(unit.rawValue) × \(reps)"
        }
        return "\(displayWeight)\(unit.rawValue)"
    }
    
    static func convertWeight(_ weight: Int, from: WeightUnit, to: WeightUnit) -> Int {
        if from == to { return weight }
        if from == .kilograms && to == .pounds {
            return Int(Double(weight) * 2.20462)
        } else {
            return Int(Double(weight) / 2.20462)
        }
    }
    
    // MARK: - Number Formatting
    
    static func formatDouble(_ value: Double, units: String? = nil) -> String {
        let formattedValue = String(format: "%.3g", value)
        if let units = units?.lowercased() {
            return "\(formattedValue) \(units)"
        }
        return formattedValue
    }
}