import Foundation
import FrugaExampleUI
import FrugaIntegration
import UIKit

/// The one place that builds the real clients. They are handed to view
/// controllers through their initializers.
struct AppComposition {
  let user: ExampleUser
  let relayClient: FrugaRelayClient

  /// Builds the clients from the settings in `bundle`'s Info.plist.
  static func load(
    bundle: Bundle = .main,
    user: ExampleUser = .demo
  ) -> Result<AppComposition, FrugaConfigurationError> {
    do {
      let configuration = try FrugaConfiguration(bundle: bundle)
      let tokenClient = TokenClient.live(configuration: configuration, userRef: user.userRef)
      let relay = FrugaRelayClient.live(configuration: configuration, tokenClient: tokenClient)
      return .success(AppComposition(user: user, relayClient: relay))
    } catch {
      return .failure(error)
    }
  }
}

extension Result where Success == AppComposition, Failure == FrugaConfigurationError {
  /// Home inside a navigation controller, or a plain message when the settings are incomplete.
  @MainActor
  func makeRootViewController() -> UIViewController {
    switch self {
    case .success(let composition):
      let home = HomeViewController(model: HomeModel(user: composition.user), relayClient: composition.relayClient)
      return UINavigationController(rootViewController: home)
    case .failure(let error):
      return ConfigurationProblemViewController(error: error)
    }
  }
}
