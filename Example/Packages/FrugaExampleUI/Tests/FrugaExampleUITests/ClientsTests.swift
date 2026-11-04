import FrugaIntegration
import FrugaSDK
import SwiftUI
import Testing

@testable import FrugaExampleUI

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ClientsTests {
  @Test func clientsCarryTheRelayClient() async {
    let clients = AppClients(relay: .preview)
    let result = await clients.relay.getBalance()
    #expect(result == .success(.init(available: 1_234.56, pending: 78.90)))
  }

  @Test func theEnvironmentDefaultsToUninstalled() {
    let values = EnvironmentValues()
    #expect(!values.clientsInstalled)
  }
}
