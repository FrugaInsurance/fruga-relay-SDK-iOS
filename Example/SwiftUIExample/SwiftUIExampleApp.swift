import FrugaExampleUI
import FrugaIntegration
import SwiftUI

/// SwiftUI integration, step by step:
/// 1. `AppComposition` reads the Fruga settings and builds the clients once.
/// 2. `installClients(_:)` puts them in the environment at the root.
/// 3. `HomeHost` shows Home; its button presents Relay.
@main
struct SwiftUIExampleApp: App {
  private let composition = AppComposition.load()

  var body: some Scene {
    WindowGroup {
      switch composition {
      case .success(let composition):
        HomeHost(user: composition.user)
          .installClients(composition.clients)
      case .failure(let error):
        ConfigurationProblemScreen(error: error)
      }
    }
  }
}
