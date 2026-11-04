import FrugaExampleUI
import FrugaIntegration
import FrugaSDK
import UIKit

/// Home for UIKit apps. The button presents Relay with
/// `relay.present(from:onError:)`, which shows it as a full-screen modal.
/// Present Relay; never push it onto a navigation stack.
final class HomeViewController: UIViewController {
  private let model: HomeModel
  private let relayClient: FrugaRelayClient
  private let observation = ObservationLoop()

  private let greetingLabel = UILabel()
  private let errorLabel = UILabel()
  private let dismissErrorButton = UIButton(type: .system)
  private let errorStack = UIStackView()

  init(model: HomeModel, relayClient: FrugaRelayClient) {
    self.model = model
    self.relayClient = relayClient
    super.init(nibName: nil, bundle: nil)
    title = HomeText.title
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never
    layoutContent()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    observation.start { [weak self] in self?.render() }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Home is visible again, so Relay is gone however it was closed.
    if model.isRelayPresented, presentedViewController == nil {
      model.relayDidClose()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    observation.stop()
  }

  private func render() {
    greetingLabel.text = model.greeting
    errorLabel.text = model.errorMessage
    errorStack.isHidden = model.errorMessage == nil
  }

  private func openRelay() {
    model.openRelay()
    relayClient.relay().present(from: self, onError: { [model] error in model.relayDidFail(error) })
    guard let relayScreen = presentedViewController as? FrugaRelayViewController else {
      // Nothing was presented (Home is already presenting something else), so Relay is not open.
      model.relayDidClose()
      return
    }
    // The balance button is added to the SDK controller's own view by design, so it sits over Relay.
    BalanceOverlayView.install(on: relayScreen.view, model: model, relayClient: relayClient)
  }

  private func layoutContent() {
    let icon = UIImageView(image: UIImage(systemName: "shield.lefthalf.filled"))
    icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle)
    icon.contentMode = .scaleAspectFit
    icon.tintColor = view.tintColor
    icon.isAccessibilityElement = false

    greetingLabel.font = .preferredFont(forTextStyle: .title2).withTraits(.traitBold)
    greetingLabel.adjustsFontForContentSizeCategory = true
    greetingLabel.numberOfLines = 0
    greetingLabel.textAlignment = .center
    greetingLabel.accessibilityTraits = .header

    let subtitle = Self.makeLabel(HomeText.subtitle, style: .body, color: .secondaryLabel)

    var configuration = UIButton.Configuration.filled()
    configuration.title = HomeText.openRelay
    configuration.buttonSize = .large
    let openButton = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in self?.openRelay() })
    openButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

    errorLabel.font = .preferredFont(forTextStyle: .body)
    errorLabel.adjustsFontForContentSizeCategory = true
    errorLabel.numberOfLines = 0
    errorLabel.textAlignment = .natural
    // Red only on the symbol: red body text falls short of 4.5:1 contrast.
    errorLabel.textColor = .label
    let errorIcon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
    errorIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
    errorIcon.tintColor = .systemRed
    errorIcon.isAccessibilityElement = false
    errorIcon.setContentHuggingPriority(.required, for: .horizontal)
    errorIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
    let errorRow = UIStackView(arrangedSubviews: [errorIcon, errorLabel])
    errorRow.axis = .horizontal
    errorRow.alignment = .top
    errorRow.spacing = 8
    dismissErrorButton.setTitle(HomeText.dismiss, for: .normal)
    dismissErrorButton.addAction(UIAction { [model] _ in model.dismissError() }, for: .touchUpInside)
    dismissErrorButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    errorStack.axis = .vertical
    errorStack.spacing = 8
    errorStack.addArrangedSubview(errorRow)
    errorStack.addArrangedSubview(dismissErrorButton)
    errorStack.isHidden = true

    let footnote = Self.makeLabel(HomeText.footnote, style: .footnote, color: .secondaryLabel)

    let stack = UIStackView(arrangedSubviews: [icon, greetingLabel, subtitle, openButton, errorStack, footnote])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)
    view.addSubview(scrollView)

    let readableWidth = stack.widthAnchor.constraint(equalTo: view.readableContentGuide.widthAnchor)
    readableWidth.priority = .defaultHigh
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      stack.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor),
      stack.widthAnchor.constraint(lessThanOrEqualToConstant: 480),
      readableWidth
    ])
  }

  private static func makeLabel(_ text: String, style: UIFont.TextStyle, color: UIColor) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: style)
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = color
    return label
  }
}

private extension UIFont {
  func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
    return UIFont(descriptor: descriptor, size: 0)
  }
}
