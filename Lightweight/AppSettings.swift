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