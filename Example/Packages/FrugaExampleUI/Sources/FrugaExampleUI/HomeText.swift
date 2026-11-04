import Foundation
import FrugaIntegration
import FrugaSDK

/// Every user-facing string of the example, shared by the SwiftUI and UIKit screens.
public enum HomeText {
  public static var title: String { String(localized: "home.title", bundle: .module) }
  public static var subtitle: String { String(localized: "home.subtitle", bundle: .module) }
  public static var openRelay: String { String(localized: "home.openRelay", bundle: .module) }
  public static var footnote: String { String(localized: "home.footnote", bundle: .module) }
  public static var checkBalance: String { String(localized: "balance.action", bundle: .module) }
  public static var balanceLoading: String { String(localized: "balance.loading", bundle: .module) }
  public static var dismiss: String { String(localized: "error.dismiss", bundle: .module) }
  public static var configurationTitle: String { String(localized: "config.title", bundle: .module) }
  public static var configurationHint: String { String(localized: "config.hint", bundle: .module) }

  public static func greeting(name: String) -> String {
    String(localized: "home.greeting \(name)", bundle: .module)
  }

  public static func balance(_ balance: FrugaBalance) -> String {
    let available = balance.available.formatted(.currency(code: "GBP"))
    let pending = balance.pending.formatted(.currency(code: "GBP"))
    return String(localized: "balance.value \(available) \(pending)", bundle: .module)
  }

  /// The message shown for a configuration problem. It names the Info.plist key;
  /// the error's own `description` stays developer-facing English.
  public static func message(for error: FrugaConfigurationError) -> String {
    switch error {
    case .missing(let key): String(localized: "config.missing \(key)", bundle: .module)
    case .invalid(let key, _): String(localized: "config.invalid \(key)", bundle: .module)
    }
  }

  /// The message shown for a Relay error: what happened, plus advice to retry when the SDK says it can be retried.
  public static func message(for error: FrugaError) -> String {
    let reason = reason(for: error.code)
    guard error.recoverable else { return reason }
    return "\(reason) \(String(localized: "error.retry", bundle: .module))"
  }

  private static func reason(for code: FrugaError.Code) -> String {
    switch code {
    case .timeout: String(localized: "error.timeout", bundle: .module)
    case .versionMismatch: String(localized: "error.versionMismatch", bundle: .module)
    case .bootstrapFailed: String(localized: "error.bootstrapFailed", bundle: .module)
    case .offline: String(localized: "error.offline", bundle: .module)
    case .bridgeTimeout: String(localized: "error.bridgeTimeout", bundle: .module)
    case .processTerminated: String(localized: "error.processTerminated", bundle: .module)
    case .tokenProviderFailed: String(localized: "error.tokenProviderFailed", bundle: .module)
    case .unsupportedEngine: String(localized: "error.unsupportedEngine", bundle: .module)
    @unknown default: String(localized: "error.unknown", bundle: .module)
    }
  }
}
