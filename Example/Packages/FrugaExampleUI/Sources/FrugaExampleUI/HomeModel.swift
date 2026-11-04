import FrugaIntegration
import FrugaSDK
import Observation

/// State and actions of the Home screen, shared by the SwiftUI and UIKit versions.
///
/// The model never holds the Relay client. Each action that needs it receives it
/// as an argument, so a screen decides where the client comes from.
@MainActor
@Observable
public final class HomeModel {
  public enum BalanceState: Equatable, Sendable {
    case idle
    case loading
    case loaded(FrugaBalance)
    case failed(FrugaError)
  }

  public let user: ExampleUser
  /// Whether Relay should currently be on screen.
  public private(set) var isRelayPresented = false
  public private(set) var balance: BalanceState = .idle
  /// The last error Relay reported, shown on Home until dismissed or Relay is reopened.
  public private(set) var relayError: FrugaError?

  private var balanceTask: Task<Void, Never>?

  public init(user: ExampleUser) {
    self.user = user
  }

  isolated deinit {
    balanceTask?.cancel()
  }

  public var greeting: String { HomeText.greeting(name: user.displayName) }

  /// The line shown with the balance button, or `nil` when there is nothing to say.
  public var balanceMessage: String? {
    switch balance {
    case .idle: nil
    case .loading: HomeText.balanceLoading
    case .loaded(let balance): HomeText.balance(balance)
    case .failed(let error): HomeText.message(for: error)
    }
  }

  public var errorMessage: String? {
    relayError.map(HomeText.message(for:))
  }

  public func openRelay() {
    relayError = nil
    balance = .idle
    isRelayPresented = true
  }

  /// Call when Relay has left the screen, however it was closed.
  public func relayDidClose() {
    balanceTask?.cancel()
    balanceTask = nil
    balance = .idle
    isRelayPresented = false
  }

  /// Call with the error Relay reports through its `onError` callback.
  public func relayDidFail(_ error: FrugaError) {
    relayError = error
  }

  public func dismissError() {
    relayError = nil
  }

  /// Reads the balance. Meant to be called while Relay is open: with no Relay
  /// screen open the SDK answers with `bridgeTimeout`.
  public func requestBalance(using client: FrugaRelayClient) {
    balanceTask?.cancel()
    balance = .loading
    balanceTask = Task { [weak self] in
      let result = await client.getBalance()
      guard !Task.isCancelled, let self else { return }
      switch result {
      case .success(let value): balance = .loaded(value)
      case .failure(let error): balance = .failed(error)
      }
    }
  }
}
