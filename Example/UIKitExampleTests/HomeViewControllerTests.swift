import FrugaExampleUI
import FrugaIntegration
import FrugaSDK
import Testing
import UIKit

@testable import UIKitExample

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct HomeViewControllerTests {
  private func allSubviews(of view: UIView) -> [UIView] {
    view.subviews + view.subviews.flatMap(allSubviews(of:))
  }

  private func labels(in view: UIView) -> [UILabel] {
    allSubviews(of: view).compactMap { $0 as? UILabel }
  }

  /// Whether `view` and every ancestor up to `root` are shown.
  private func isShown(_ view: UIView, in root: UIView) -> Bool {
    var current: UIView? = view
    while let candidate = current, candidate !== root {
      if candidate.isHidden { return false }
      current = candidate.superview
    }
    return current === root
  }

  private func settle() async {
    for _ in 0..<20 { await Task.yield() }
  }

  @Test func showsTheGreetingAndTheOpenButton() {
    let model = HomeModel(user: .demo)
    let controller = HomeViewController(model: model, relayClient: .preview)
    controller.loadViewIfNeeded()
    controller.beginAppearanceTransition(true, animated: false)
    controller.endAppearanceTransition()

    #expect(labels(in: controller.view).contains { $0.text == model.greeting })
    #expect(allSubviews(of: controller.view).contains { ($0 as? UIButton)?.configuration?.title == HomeText.openRelay })
    #expect(controller.title == HomeText.title)
  }

  @Test func showsAndHidesRelayErrors() async {
    let model = HomeModel(user: .demo)
    let controller = HomeViewController(model: model, relayClient: .preview)
    controller.loadViewIfNeeded()
    controller.beginAppearanceTransition(true, animated: false)
    controller.endAppearanceTransition()

    let error = FrugaError(code: .offline, message: "offline", recoverable: false)
    model.relayDidFail(error)
    await settle()
    let errorLabel = labels(in: controller.view).first { $0.text == HomeText.message(for: error) }
    #expect(errorLabel.map { isShown($0, in: controller.view) } == true)
    #expect(errorLabel?.textColor == .label)

    model.dismissError()
    await settle()
    #expect(!labels(in: controller.view).contains { $0.text == HomeText.message(for: error) })
    controller.beginAppearanceTransition(false, animated: false)
    controller.endAppearanceTransition()
  }

  @Test func openingRelayWithNothingPresentedLeavesItClosed() {
    let model = HomeModel(user: .demo)
    let controller = HomeViewController(model: model, relayClient: .preview)
    controller.loadViewIfNeeded()
    // Not in a window, so UIKit refuses the presentation.
    let button = allSubviews(of: controller.view).compactMap { $0 as? UIButton }
      .first { $0.configuration?.title == HomeText.openRelay }
    button?.sendActions(for: .primaryActionTriggered)
    #expect(controller.presentedViewController == nil)
    #expect(!model.isRelayPresented)
  }

  @Test func theBalanceOverlayReadsTheBalance() async {
    let model = HomeModel(user: .demo)
    model.openRelay()
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let window = UIWindow(frame: host.frame)
    window.addSubview(host)
    window.isHidden = false
    BalanceOverlayView.install(on: host, model: model, relayClient: .preview)

    let button = allSubviews(of: host).compactMap { $0 as? UIButton }.first
    #expect(button?.configuration?.title == HomeText.checkBalance)
    button?.sendActions(for: .primaryActionTriggered)
    await settle()
    #expect(model.balance == .loaded(FrugaBalance(available: 1_234.56, pending: 78.90)))
    #expect(labels(in: host).contains { $0.text == model.balanceMessage && !$0.isHidden })
    window.isHidden = true
  }
}
