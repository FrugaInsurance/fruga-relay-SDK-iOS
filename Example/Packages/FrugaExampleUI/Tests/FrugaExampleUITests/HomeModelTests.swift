import FrugaIntegration
import FrugaSDK
import Testing

@testable import FrugaExampleUI

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct HomeModelTests {
  private let balance = FrugaBalance(available: 10, pending: 2)
  private let offline = FrugaError(code: .offline, message: "offline", recoverable: true)

  private func client(returning result: Result<FrugaBalance, FrugaError>) -> FrugaRelayClient {
    var client = FrugaRelayClient.preview
    client.getBalance = { result }
    return client
  }

  /// Waits until `condition` holds, yielding between checks.
  private func settle(_ condition: () -> Bool) async {
    for _ in 0..<1_000 where !condition() {
      await Task.yield()
    }
  }

  @Test func startsIdleAndGreetsTheUser() {
    let model = HomeModel(user: .demo)
    #expect(!model.isRelayPresented)
    #expect(model.balance == .idle)
    #expect(model.relayError == nil)
    #expect(model.balanceMessage == nil)
    #expect(model.errorMessage == nil)
    #expect(model.greeting.contains("Alex Example"))
  }

  @Test func openRelayPresentsAndClearsPreviousResults() {
    let model = HomeModel(user: .demo)
    model.relayDidFail(offline)
    model.openRelay()
    #expect(model.isRelayPresented)
    #expect(model.relayError == nil)
    #expect(model.balance == .idle)
  }

  @Test func relayDidCloseResetsPresentationAndBalance() async {
    let model = HomeModel(user: .demo)
    model.openRelay()
    model.requestBalance(using: client(returning: .success(balance)))
    model.relayDidClose()
    #expect(!model.isRelayPresented)
    #expect(model.balance == .idle)
  }

  @Test func relayErrorsAreKeptUntilDismissed() {
    let model = HomeModel(user: .demo)
    model.relayDidFail(offline)
    #expect(model.relayError == offline)
    #expect(model.errorMessage == HomeText.message(for: offline))
    model.dismissError()
    #expect(model.relayError == nil)
  }

  @Test func balanceSuccessIsPublished() async {
    let model = HomeModel(user: .demo)
    model.openRelay()
    model.requestBalance(using: client(returning: .success(balance)))
    #expect(model.balance == .loading)
    #expect(model.balanceMessage == HomeText.balanceLoading)
    await settle { model.balance != .loading }
    #expect(model.balance == .loaded(balance))
    #expect(model.balanceMessage == HomeText.balance(balance))
  }

  @Test func balanceFailureIsPublished() async {
    let model = HomeModel(user: .demo)
    model.requestBalance(using: client(returning: .failure(offline)))
    await settle { model.balance != .loading }
    #expect(model.balance == .failed(offline))
    #expect(model.balanceMessage == HomeText.message(for: offline))
  }

  @Test func aNewRequestReplacesAnUnfinishedOne() async {
    let model = HomeModel(user: .demo)
    model.openRelay()
    model.requestBalance(using: client(returning: .failure(offline)))
    model.requestBalance(using: client(returning: .success(balance)))
    await settle { model.balance != .loading }
    #expect(model.balance == .loaded(balance))
  }

  @Test func closingWhileLoadingDropsTheLateAnswer() async {
    let model = HomeModel(user: .demo)
    model.openRelay()
    model.requestBalance(using: client(returning: .success(balance)))
    model.relayDidClose()
    for _ in 0..<50 { await Task.yield() }
    #expect(model.balance == .idle)
  }
}
