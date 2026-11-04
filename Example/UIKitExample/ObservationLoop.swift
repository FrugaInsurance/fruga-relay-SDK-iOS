import Observation

/// Runs `apply` now and again every time an `@Observable` value it read changes.
///
/// Observation reports one change per registration, so the loop registers again
/// after each one. `apply` should read the values it displays and update the
/// views; call `stop()` when the screen goes away.
@MainActor
final class ObservationLoop {
  private var apply: (@MainActor () -> Void)?
  /// Distinguishes the current run from earlier ones whose registration is still pending.
  private var generation = 0

  func start(_ apply: @escaping @MainActor () -> Void) {
    generation += 1
    self.apply = apply
    track(generation: generation)
  }

  func stop() {
    generation += 1
    apply = nil
  }

  private func track(generation: Int) {
    guard generation == self.generation, let apply else { return }
    withObservationTracking {
      apply()
    } onChange: { [weak self] in
      // The change has not landed yet; track again on the next turn of the main actor.
      Task { @MainActor [weak self] in self?.track(generation: generation) }
    }
  }
}
