import FrugaExampleUI
import FrugaIntegration
import UIKit

/// The "Check balance" button shown over the Relay screen.
///
/// `getBalance()` only works while a Relay screen is open, so the button lives
/// on the Relay screen itself rather than on Home.
final class BalanceOverlayView: UIView {
  private let model: HomeModel
  private let relayClient: FrugaRelayClient
  private let observation = ObservationLoop()
  private let messageLabel = UILabel()
  private var lastAnnouncement: String?

  /// Adds the overlay at the bottom of `host`.
  static func install(on host: UIView, model: HomeModel, relayClient: FrugaRelayClient) {
    let overlay = BalanceOverlayView(model: model, relayClient: relayClient)
    overlay.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(overlay)
    let preferredWidth = overlay.widthAnchor.constraint(equalToConstant: 480)
    preferredWidth.priority = .defaultHigh
    NSLayoutConstraint.activate([
      overlay.centerXAnchor.constraint(equalTo: host.centerXAnchor),
      overlay.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor, constant: -16),
      overlay.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 16),
      overlay.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -16),
      preferredWidth
    ])
  }

  private init(model: HomeModel, relayClient: FrugaRelayClient) {
    self.model = model
    self.relayClient = relayClient
    super.init(frame: .zero)
    build()
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      observation.stop()
    } else {
      observation.start { [weak self] in self?.render() }
    }
  }

  private func build() {
    layer.cornerRadius = 16
    clipsToBounds = true

    let background = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    background.translatesAutoresizingMaskIntoConstraints = false
    addSubview(background)

    messageLabel.font = .preferredFont(forTextStyle: .callout)
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    messageLabel.isHidden = true

    var configuration = UIButton.Configuration.bordered()
    configuration.title = HomeText.checkBalance
    let model = model
    let relayClient = relayClient
    let button = UIButton(
      configuration: configuration,
      primaryAction: UIAction { _ in model.requestBalance(using: relayClient) }
    )
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

    let stack = UIStackView(arrangedSubviews: [messageLabel, button])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)

    NSLayoutConstraint.activate([
      background.topAnchor.constraint(equalTo: topAnchor),
      background.bottomAnchor.constraint(equalTo: bottomAnchor),
      background.leadingAnchor.constraint(equalTo: leadingAnchor),
      background.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
    ])
  }

  private func render() {
    let message = model.balanceMessage
    messageLabel.text = message
    messageLabel.isHidden = message == nil
    if let message, message != lastAnnouncement {
      UIAccessibility.post(notification: .announcement, argument: message)
    }
    lastAnnouncement = message
  }
}
