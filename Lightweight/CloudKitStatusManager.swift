//
//  CloudKitStatusManager.swift
//  Lightweight
//
//  Surfaces whether iCloud sync is actually available, so the user can tell at
//  a glance if their data is being backed up.
//

import CloudKit
import SwiftUI

@MainActor
final class CloudKitStatusManager: ObservableObject {
  enum Status: Equatable {
    case unknown
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine

    init(_ accountStatus: CKAccountStatus) {
      switch accountStatus {
      case .available: self = .available
      case .noAccount: self = .noAccount
      case .restricted: self = .restricted
      case .temporarilyUnavailable: self = .temporarilyUnavailable
      case .couldNotDetermine: self = .couldNotDetermine
      @unknown default: self = .couldNotDetermine
      }
    }

    var label: String {
      switch self {
      case .unknown: return "Checking…"
      case .available: return "On"
      case .noAccount: return "Not signed in to iCloud"
      case .restricted: return "Restricted"
      case .temporarilyUnavailable: return "Temporarily unavailable"
      case .couldNotDetermine: return "Unavailable"
      }
    }

    /// Guidance shown when sync isn't healthy, so the user knows what to do.
    var advice: String? {
      switch self {
      case .available, .unknown:
        return nil
      case .noAccount:
        return "Sign in to iCloud in Settings and enable iCloud Drive to back up your data."
      case .restricted:
        return "iCloud is restricted on this device (for example by parental controls or a profile)."
      case .temporarilyUnavailable:
        return "iCloud is temporarily unavailable. Your data is safe on this device and will sync when it returns."
      case .couldNotDetermine:
        return "Your data is safe on this device but may not be backing up to iCloud."
      }
    }

    var symbol: String {
      switch self {
      case .available: return "checkmark.icloud.fill"
      case .unknown: return "icloud"
      default: return "exclamationmark.icloud.fill"
      }
    }

    var isHealthy: Bool { self == .available }
  }

  @Published private(set) var status: Status = .unknown

  func refresh() {
    Task {
      do {
        let accountStatus = try await CKContainer(identifier: LightweightApp.cloudKitContainerID).accountStatus()
        self.status = Status(accountStatus)
      } catch {
        self.status = .couldNotDetermine
      }
    }
  }
}
