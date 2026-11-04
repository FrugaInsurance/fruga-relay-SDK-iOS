import FrugaSDK

/// The app's view of Fruga Relay.
///
/// All members run on the main actor because `FrugaRelay` is main-actor bound.
public struct FrugaRelayClient: Sendable {
  /// The relay to present. Always the same instance.
  public var relay: @MainActor @Sendable () -> FrugaRelay
  /// Reads the user's balance. Only works while a Relay screen is open; with
  /// none open it fails with `FrugaError.Code.bridgeTimeout`.
  public var getBalance: @MainActor @Sendable () async -> Result<FrugaBalance, FrugaError>

  public init(
    relay: @escaping @MainActor @Sendable () -> FrugaRelay,
    getBalance: @escaping @MainActor @Sendable () async -> Result<FrugaBalance, FrugaError>
  ) {
    self.relay = relay
    self.getBalance = getBalance
  }
}

extension FrugaRelayClient {
  /// Creates the real `FrugaRelay`, authenticating with `tokenClient`.
  public static func live(configuration: FrugaConfiguration, tokenClient: TokenClient) -> FrugaRelayClient {
    let options = FrugaRelayOptions(apiBaseUrl: configuration.apiBaseURL.absoluteString, tokenTtlSeconds: 900)
    return make(
      holder: RelayHolder(makeRelay: {
        FrugaRelay(partnerKey: configuration.partnerKey, tokenProvider: tokenClient.token, options: options)
      })
    )
  }

  /// A relay with a placeholder partner key and token, for previews. Balance
  /// reads answer with a fixed value without calling the SDK; presenting the
  /// relay still loads the Relay screen, which cannot sign in.
  public static var preview: FrugaRelayClient {
    var client = make(holder: placeholderHolder(tokenClient: .preview))
    client.getBalance = { .success(FrugaBalance(available: 1_234.56, pending: 78.90)) }
    return client
  }

  /// Every balance read fails with `bridgeTimeout`.
  public static var failing: FrugaRelayClient {
    var client = make(holder: placeholderHolder(tokenClient: .failing))
    client.getBalance = {
      .failure(FrugaError(code: .bridgeTimeout, message: "No Relay screen is open", recoverable: true))
    }
    return client
  }

  private static func make(holder: RelayHolder) -> FrugaRelayClient {
    FrugaRelayClient(
      relay: { holder.relay },
      getBalance: { await holder.relay.getBalance() }
    )
  }

  private static func placeholderHolder(tokenClient: TokenClient) -> RelayHolder {
    RelayHolder(makeRelay: {
      FrugaRelay(partnerKey: "pk_placeholder", tokenProvider: tokenClient.token)
    })
  }
}
