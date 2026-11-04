import FrugaIntegration
import SwiftUI

/// The dependencies the screens read from the SwiftUI environment.
public struct AppClients: Sendable {
  public var relay: FrugaRelayClient

  public init(relay: FrugaRelayClient) {
    self.relay = relay
  }
}

extension EnvironmentValues {
  @Entry public var frugaRelayClient: FrugaRelayClient = .preview
  @Entry var clientsInstalled = false
}

extension View {
  /// Puts every client into the environment. Apply it once, at the root of the
  /// app. In debug builds a screen that finds no installed clients stops with
  /// an assertion, so a forgotten call fails on first launch instead of quietly
  /// running on preview data.
  public func installClients(_ clients: AppClients) -> some View {
    environment(\.frugaRelayClient, clients.relay)
      .environment(\.clientsInstalled, true)
  }
}
