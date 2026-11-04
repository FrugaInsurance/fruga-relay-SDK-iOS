import Foundation
import FrugaExampleUI
import FrugaIntegration
import Testing

@testable import SwiftUIExample

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct AppCompositionTests {
  @Test func readsTheAppsOwnSettings() {
    switch AppComposition.load() {
    case .success(let composition):
      #expect(composition.user == .demo)
    case .failure(let error):
      // Config/Fruga.xcconfig still holds its placeholders.
      #expect(error == .invalid(key: FrugaConfiguration.InfoKey.partnerKey, reason: "replace the placeholder value"))
    }
  }

  @Test func reportsIncompleteSettings() {
    let result = AppComposition.load(bundle: Bundle(for: NSObject.self))
    guard case .failure(let error) = result else {
      Issue.record("Expected a configuration failure")
      return
    }
    #expect(error == .missing(key: FrugaConfiguration.InfoKey.partnerKey))
  }
}
