//
//  HapticManager.swift
//  Lightweight
//
//  Haptic feedback utilities
//

import UIKit

enum HapticManager {
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // Convenience methods
    static func success() {
        notification(.success)
    }
    
    static func error() {
        notification(.error)
    }
    
    static func warning() {
        notification(.warning)
    }
    
    static func lightImpact() {
        impact(.light)
    }
    
    static func mediumImpact() {
        impact(.medium)
    }
}