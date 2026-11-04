import Foundation
import Testing

@testable import FrugaIntegration

@Suite(.timeLimit(.minutes(1)))
struct FrugaConfigurationTests {
  private let valid: [String: Any] = [
    FrugaConfiguration.InfoKey.partnerKey: "pk_test",
    FrugaConfiguration.InfoKey.apiBaseURL: "https://api.test.example.com",
    FrugaConfiguration.InfoKey.tokenURL: "https://backend.example.com/api/fruga/assertion"
  ]

  @Test func readsAValidInfoDictionary() throws {
    let configuration = try FrugaConfiguration(infoDictionary: valid)
    #expect(configuration.partnerKey == "pk_test")
    #expect(configuration.apiBaseURL.absoluteString == "https://api.test.example.com")
    #expect(configuration.tokenURL.absoluteString == "https://backend.example.com/api/fruga/assertion")
  }

  @Test(arguments: [
    FrugaConfiguration.InfoKey.partnerKey,
    FrugaConfiguration.InfoKey.apiBaseURL,
    FrugaConfiguration.InfoKey.tokenURL
  ])
  func reportsAMissingKey(key: String) {
    var info = valid
    info[key] = nil
    #expect(throws: FrugaConfigurationError.missing(key: key)) {
      try FrugaConfiguration(infoDictionary: info)
    }
  }

  @Test func treatsBlankAsMissing() {
    var info = valid
    info[FrugaConfiguration.InfoKey.partnerKey] = "   "
    #expect(throws: FrugaConfigurationError.missing(key: FrugaConfiguration.InfoKey.partnerKey)) {
      try FrugaConfiguration(infoDictionary: info)
    }
  }

  @Test func rejectsAnUnexpandedBuildSetting() {
    var info = valid
    info[FrugaConfiguration.InfoKey.partnerKey] = "$(FRUGA_PARTNER_KEY)"
    #expect(
      throws: FrugaConfigurationError.invalid(
        key: FrugaConfiguration.InfoKey.partnerKey,
        reason: "the build setting is not defined"
      )
    ) {
      try FrugaConfiguration(infoDictionary: info)
    }
  }

  @Test(arguments: [
    (FrugaConfiguration.InfoKey.partnerKey, "YOUR_PARTNER_KEY"),
    (FrugaConfiguration.InfoKey.apiBaseURL, "https://api.example.com"),
    (FrugaConfiguration.InfoKey.tokenURL, "https://your-backend.example.com/fruga/token")
  ])
  func rejectsAPlaceholder(key: String, value: String) {
    var info = valid
    info[key] = value
    #expect(throws: FrugaConfigurationError.invalid(key: key, reason: "replace the placeholder value")) {
      try FrugaConfiguration(infoDictionary: info)
    }
  }

  @Test(arguments: ["http://api.example.com", "not a url", "ftp://api.example.com", "https://"])
  func rejectsANonHttpsURL(value: String) {
    var info = valid
    info[FrugaConfiguration.InfoKey.apiBaseURL] = value
    #expect(throws: FrugaConfigurationError.self) {
      try FrugaConfiguration(infoDictionary: info)
    }
  }

  @Test func readsFromABundle() {
    #expect(throws: FrugaConfigurationError.self) {
      try FrugaConfiguration(bundle: Bundle(for: BundleToken.self))
    }
  }

  @Test func descriptionsNameTheKey() {
    #expect(FrugaConfigurationError.missing(key: "FrugaPartnerKey").description.contains("FrugaPartnerKey"))
    #expect(FrugaConfigurationError.invalid(key: "FrugaTokenURL", reason: "why").description.contains("why"))
  }
}

private final class BundleToken {}
