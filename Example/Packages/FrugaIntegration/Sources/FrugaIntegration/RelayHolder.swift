import FrugaSDK

/// Owns the one ``FrugaRelay`` the app uses.
///
/// One `FrugaRelay` is one Relay screen and one presentation path, so the app keeps
/// a single instance for as long as it needs Relay rather than building a new
/// one per screen. The relay is created on first use.
@MainActor
final class RelayHolder {
  private let makeRelay: @MainActor @Sendable () -> FrugaRelay
  private var current: FrugaRelay?

  nonisolated init(makeRelay: @escaping @MainActor @Sendable () -> FrugaRelay) {
    self.makeRelay = makeRelay
  }

  var relay: FrugaRelay {
    if let current { return current }
    let relay = makeRelay()
    current = relay
    return relay
  }
}
