import Foundation

/// Everything the SDK needs from your build settings, read once at launch.
///
/// The values live in `Config/Fruga.xcconfig`, flow into the app's Info.plist
/// as `$(FRUGA_*)` entries, and are read back here. Reading them in one place
/// means a missing or mistyped setting is reported on launch with the name of
/// the setting to fix, instead of surfacing later as a failed network call.
public struct FrugaConfiguration: Sendable, Equatable {
  /// Info.plist keys the configuration is read from.
  public enum InfoKey {
    public static let partnerKey = "FrugaPartnerKey"
    public static let apiBaseURL = "FrugaAPIBaseURL"
    public static let tokenURL = "FrugaTokenURL"
  }

  /// The values `Config/Fruga.xcconfig` ships with. They are reported like a
  /// bad value, so an unconfigured app says so on launch.
  private static let placeholders: Set<String> = [
    "YOUR_PARTNER_KEY",
    "https://api.example.com",
    "https://your-backend.example.com/fruga/token"
  ]

  /// The partner key issued by Fruga.
  public let partnerKey: String
  /// Base URL of the Fruga API.
  public let apiBaseURL: URL
  /// Endpoint on your backend that mints a Fruga access token for a user.
  public let tokenURL: URL

  init(partnerKey: String, apiBaseURL: URL, tokenURL: URL) {
    self.partnerKey = partnerKey
    self.apiBaseURL = apiBaseURL
    self.tokenURL = tokenURL
  }

  /// Reads and validates the configuration from an Info.plist dictionary.
  public init(infoDictionary: [String: Any]) throws(FrugaConfigurationError) {
    partnerKey = try Self.string(InfoKey.partnerKey, in: infoDictionary)
    apiBaseURL = try Self.httpsURL(InfoKey.apiBaseURL, in: infoDictionary)
    tokenURL = try Self.httpsURL(InfoKey.tokenURL, in: infoDictionary)
  }

  /// Reads and validates the configuration from a bundle's Info.plist.
  public init(bundle: Bundle = .main) throws(FrugaConfigurationError) {
    try self.init(infoDictionary: bundle.infoDictionary ?? [:])
  }

  private static func string(_ key: String, in info: [String: Any]) throws(FrugaConfigurationError) -> String {
    guard let value = (info[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
      throw .missing(key: key)
    }
    // An unexpanded "$(FRUGA_...)" means the xcconfig does not define the setting.
    guard !value.contains("$(") else { throw .invalid(key: key, reason: "the build setting is not defined") }
    guard !placeholders.contains(value) else { throw .invalid(key: key, reason: "replace the placeholder value") }
    return value
  }

  private static func httpsURL(_ key: String, in info: [String: Any]) throws(FrugaConfigurationError) -> URL {
    let value = try string(key, in: info)
    guard let url = URL(string: value), url.scheme == "https", url.host() != nil else {
      throw .invalid(key: key, reason: "expected an https URL")
    }
    return url
  }
}

/// Why a ``FrugaConfiguration`` could not be built. `description` is a
/// developer-facing English message naming the Info.plist key; each key is fed
/// by an `FRUGA_*` setting in `Config/Fruga.xcconfig`. Screens show their own
/// localized copy for each case instead.
public enum FrugaConfigurationError: Error, Equatable, Sendable, CustomStringConvertible {
  case missing(key: String)
  case invalid(key: String, reason: String)

  public var description: String {
    switch self {
    case .missing(let key):
      "Info.plist key \(key) is missing or empty. Set the matching FRUGA_* value in Config/Fruga.xcconfig."
    case .invalid(let key, let reason):
      "Info.plist key \(key) is invalid: \(reason). Check the matching FRUGA_* value in Config/Fruga.xcconfig."
    }
  }
}
