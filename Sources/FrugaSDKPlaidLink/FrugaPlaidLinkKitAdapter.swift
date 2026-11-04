#if canImport(LinkKit) && canImport(UIKit)
import FrugaSDK
import LinkKit
import UIKit

@objc(FrugaPlaidLinkKitAdapter)
@MainActor
final class FrugaPlaidLinkKitAdapter: NSObject, _FrugaPlaidLinkAdapter {
  private var session: PlaidLinkSession?
  private var onLoad: (@MainActor () -> Void)?
  private var onFinish: (@MainActor (_FrugaPlaidLinkOutcome) -> Void)?
  private var presentHandler: (@MainActor (UIViewController) -> Void)?
  private var dismissHandler: (@MainActor (UIViewController) -> Void)?

  required override init() {
    super.init()
  }

  func prepare(
    linkToken: String,
    onLoad: @escaping @MainActor () -> Void,
    onFinish: @escaping @MainActor (_FrugaPlaidLinkOutcome) -> Void
  ) throws {
    self.onLoad = onLoad
    self.onFinish = onFinish
    do {
      session = try Plaid.createPlaidLinkSession(configuration: Self.configuration(linkToken: linkToken, owner: self))
    } catch ConfigurationError.invalidToken {
      cancel()
      throw _FrugaPlaidLinkPrepareError.invalidToken
    } catch {
      cancel()
      throw _FrugaPlaidLinkPrepareError.failed
    }
  }

  func show(
    present: @escaping @MainActor (UIViewController) -> Void,
    dismiss: @escaping @MainActor (UIViewController) -> Void
  ) {
    guard let session else { return }
    presentHandler = present
    dismissHandler = dismiss
    session.open(using: Self.presentationMethod(owner: self))
  }

  func cancel() {
    session = nil
    onLoad = nil
    onFinish = nil
    presentHandler = nil
    dismissHandler = nil
  }

  private func didLoad() {
    onLoad?()
  }

  private func didFinish(_ outcome: _FrugaPlaidLinkOutcome) {
    onFinish?(outcome)
  }

  private func present(_ viewController: UIViewController) {
    presentHandler?(viewController)
  }

  private func dismiss(_ viewController: UIViewController) {
    dismissHandler?(viewController)
  }

  private nonisolated static func configuration(
    linkToken: String,
    owner: FrugaPlaidLinkKitAdapter
  ) -> LinkTokenConfiguration {
    LinkTokenConfiguration(
      token: linkToken,
      onSuccess: { [weak owner] success in
        let outcome = outcome(for: success)
        Task { @MainActor in owner?.didFinish(outcome) }
      },
      onExit: { [weak owner] exit in
        let outcome = outcome(for: exit)
        Task { @MainActor in owner?.didFinish(outcome) }
      },
      onEvent: nil,
      onLoad: { [weak owner] in Task { @MainActor in owner?.didLoad() } }
    )
  }

  private nonisolated static func presentationMethod(owner: FrugaPlaidLinkKitAdapter) -> PresentationMethod {
    .custom(
      { [weak owner] viewController in Task { @MainActor in owner?.present(viewController) } },
      { [weak owner] viewController in Task { @MainActor in owner?.dismiss(viewController) } }
    )
  }

  private nonisolated static func outcome(for success: LinkSuccess) -> _FrugaPlaidLinkOutcome {
    LinkKitOutcomeMapping.success(
      publicToken: success.publicToken,
      linkSessionId: success.metadata.linkSessionID,
      institution: (id: success.metadata.institution.id, name: success.metadata.institution.name),
      accountCount: success.metadata.accounts.count
    )
  }

  private nonisolated static func outcome(for exit: LinkExit) -> _FrugaPlaidLinkOutcome {
    let metadata = exit.metadata
    return LinkKitOutcomeMapping.exit(
      linkSessionId: metadata.linkSessionID,
      plaidRequestId: metadata.requestID,
      exitStatus: metadata.status,
      error: exit.error.map {
        LinkKitExitErrorFields(code: $0.errorCode, message: $0.errorMessage, displayMessage: $0.displayMessage)
      }
    )
  }
}
#endif
