import FrugaIntegration
import FrugaSDK
import Testing

@testable import FrugaExampleUI

@Suite(.timeLimit(.minutes(1)))
struct HomeTextTests {
  private let codes: [FrugaError.Code] = [
    .timeout, .versionMismatch, .bootstrapFailed, .offline,
    .bridgeTimeout, .processTerminated, .tokenProviderFailed, .unsupportedEngine
  ]

  @Test func everyErrorCodeHasItsOwnMessage() {
    let messages = codes.map { HomeText.message(for: FrugaError(code: $0, message: "m", recoverable: false)) }
    #expect(Set(messages).count == codes.count)
    #expect(!messages.contains { $0.contains("error.") })
  }

  @Test func recoverableErrorsSuggestTryingAgain() {
    let fixed = HomeText.message(for: FrugaError(code: .offline, message: "m", recoverable: false))
    let retryable = HomeText.message(for: FrugaError(code: .offline, message: "m", recoverable: true))
    #expect(retryable.hasPrefix(fixed))
    #expect(retryable.count > fixed.count)
  }

  @Test func balanceShowsBothAmountsInPounds() {
    let text = HomeText.balance(FrugaBalance(available: 1_234.5, pending: 6))
    // Formatted with the runner's locale, as the app does, so the test holds in any region.
    #expect(text.contains((1_234.5).formatted(.currency(code: "GBP"))))
    #expect(text.contains((6.0).formatted(.currency(code: "GBP"))))
  }

  @Test func configurationProblemsNameTheKeyInLocalizedCopy() {
    let missing = FrugaConfigurationError.missing(key: "FrugaPartnerKey")
    let invalid = FrugaConfigurationError.invalid(key: "FrugaTokenURL", reason: "expected an https URL")
    #expect(HomeText.message(for: missing) == "FrugaPartnerKey is missing or empty.")
    #expect(HomeText.message(for: invalid) == "FrugaTokenURL has an invalid value.")
    #expect(HomeText.message(for: invalid) != invalid.description)
  }

  @Test func staticStringsAreLocalized() {
    let strings = [
      HomeText.title, HomeText.subtitle, HomeText.openRelay, HomeText.footnote, HomeText.checkBalance,
      HomeText.balanceLoading, HomeText.dismiss, HomeText.configurationTitle, HomeText.configurationHint,
      HomeText.greeting(name: "Ana")
    ]
    let keyPrefixes = ["home.", "balance.", "error.", "config."]
    #expect(strings.allSatisfy { text in !text.isEmpty && !keyPrefixes.contains { text.hasPrefix($0) } })
    #expect(HomeText.greeting(name: "Ana") == "Welcome, Ana")
  }
}
