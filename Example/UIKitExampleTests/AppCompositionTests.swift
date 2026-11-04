import Foundation
import FrugaExampleUI
import FrugaIntegration
import Testing
import UIKit

@testable import UIKitExample

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct AppCompositionTests {
  @Test func buildsTheRootFromTheAppsOwnSettings() throws {
    let result = AppComposition.load()
    let root = result.makeRootViewController()
    switch result {
    case .success:
      let navigation = try #require(root as? UINavigationController)
      #expect(navigation.viewControllers.first is HomeViewController)
    case .failure:
      // Config/Fruga.xcconfig still holds its placeholders.
      #expect(root is ConfigurationProblemViewController)
    }
  }

  @Test func reportsIncompleteSettings() throws {
    let result = AppComposition.load(bundle: Bundle(for: NSObject.self))
    guard case .failure(let error) = result else {
      Issue.record("Expected a configuration failure")
      return
    }
    #expect(error == .missing(key: FrugaConfiguration.InfoKey.partnerKey))
    let root = result.makeRootViewController()
    #expect(root is ConfigurationProblemViewController)
    root.loadViewIfNeeded()
    #expect(root.view.subviews.count == 1)
  }
}
