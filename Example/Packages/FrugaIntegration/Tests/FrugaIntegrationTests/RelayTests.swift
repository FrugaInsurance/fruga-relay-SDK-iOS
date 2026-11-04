import Foundation
import FrugaSDK
import Testing

@testable import FrugaIntegration

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct RelayHolderTests {
  private func makeHolder(counter: Counter) -> RelayHolder {
    RelayHolder(makeRelay: {
      counter.increment()
      return FrugaRelay(partnerKey: "pk_test", tokenProvider: { _ in "token" })
    })
  }

  @Test func createsTheRelayOnFirstUseOnly() {
    let counter = Counter()
    let holder = makeHolder(counter: counter)
    #expect(counter.value == 0)
    let first = holder.relay
    let second = holder.relay
    #expect(first === second)
    #expect(counter.value == 1)
  }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct FrugaRelayClientTests {
  private let configuration = FrugaConfiguration(
    partnerKey: "pk_test",
    apiBaseURL: URL(string: "https://api.example.com")!,
    tokenURL: URL(string: "https://backend.example.com/api/fruga/assertion")!
  )

  @Test func liveReturnsTheSameRelayEveryTime() {
    let client = FrugaRelayClient.live(configuration: configuration, tokenClient: .preview)
    #expect(client.relay() === client.relay())
  }

  @Test func liveBalanceFailsWhenNoRelayScreenIsOpen() async {
    let client = FrugaRelayClient.live(configuration: configuration, tokenClient: .preview)
    let result = await client.getBalance()
    guard case .failure(let error) = result else {
      Issue.record("Expected a failure, got \(result)")
      return
    }
    #expect(error.code == .bridgeTimeout)
  }

  @Test func previewAnswersAFixedBalance() async {
    let result = await FrugaRelayClient.preview.getBalance()
    #expect(result == .success(FrugaBalance(available: 1_234.56, pending: 78.90)))
  }

  @Test func failingFailsEveryBalanceRead() async {
    let client = FrugaRelayClient.failing
    guard case .failure(let error) = await client.getBalance() else {
      Issue.record("Expected a failure")
      return
    }
    #expect(error.code == .bridgeTimeout)
    #expect(client.relay() === client.relay())
  }
}

@MainActor
private final class Counter {
  private(set) var value = 0
  func increment() { value += 1 }
}
