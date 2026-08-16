import SwiftUI

class AppSettings: ObservableObject {
    private static let weightUnitKey = "weightUnit"
    
    @Published var weightUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(weightUnit.rawValue, forKey: Self.weightUnitKey)
        }
    }
    
    init() {
        let savedValue = UserDefaults.standard.string(forKey: Self.weightUnitKey) ?? WeightUnit.kilograms.rawValue
        self.weightUnit = WeightUnit(rawValue: savedValue) ?? .kilograms
    }
}

enum WeightUnit: String {
    case kilograms = "kg"
    case pounds = "lb"

    var label: String {
        switch self {
        case .kilograms: return "Kilograms"
        case .pounds: return "Pounds"
        }
    }

    /// Multiplier to convert a kilogram value into this unit.
    private var perKilogram: Double {
        switch self {
        case .kilograms: return 1.0
        case .pounds: return 2.2046226218
        }
    }

    /// Convert a canonical kilogram value into this unit for display/entry.
    func fromKilograms(_ kg: Double) -> Double {
        kg * perKilogram
    }

    /// Convert a value expressed in this unit back into canonical kilograms.
    func toKilograms(_ value: Double) -> Double {
        value / perKilogram
    }

    /// Sensible increment for +/- steppers in this unit.
    var step: Double {
        switch self {
        case .kilograms: return 2.5
        case .pounds: return 5
        }
    }
}

private struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings()
}

extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}