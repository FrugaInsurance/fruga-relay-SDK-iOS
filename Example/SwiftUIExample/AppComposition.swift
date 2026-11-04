import Foundation
import FrugaExampleUI
import FrugaIntegration

/// The one place that builds the real clients.
struct AppComposition {
  let user: ExampleUser
  let clients: AppClients

  /// Builds the clients from the settings in `bundle`'s Info.plist.
  static func load(bundle: Bundle = .main, user: ExampleUser = .demo) -> Result<AppComposition, FrugaConfigurationError> {
    do {
      let configuration = try FrugaConfiguration(bundle: bundle)
      let tokenClient = TokenClient.live(configuration: configuration, userRef: user.userRef)
      let relay = FrugaRelayClient.live(configuration: configuration, tokenClient: tokenClient)
      return .success(AppComposition(user: user, clients: AppClients(relay: relay)))
    } catch {
      return .failure(error)
    }
  }
}
