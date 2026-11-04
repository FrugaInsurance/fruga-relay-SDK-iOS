import FrugaExampleUI
import FrugaIntegration
import UIKit

/// Shown instead of Home when the build settings are incomplete.
final class ConfigurationProblemViewController: UIViewController {
  private let message: String

  init(error: FrugaConfigurationError) {
    message = HomeText.message(for: error)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let titleLabel = UILabel()
    titleLabel.text = HomeText.configurationTitle
    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.accessibilityTraits = .header

    let messageLabel = UILabel()
    messageLabel.text = message
    messageLabel.font = .preferredFont(forTextStyle: .body)

    let hintLabel = UILabel()
    hintLabel.text = HomeText.configurationHint
    hintLabel.font = .preferredFont(forTextStyle: .body)
    hintLabel.textColor = .secondaryLabel

    let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, hintLabel])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    for label in [titleLabel, messageLabel, hintLabel] {
      label.numberOfLines = 0
      label.textAlignment = .center
      label.adjustsFontForContentSizeCategory = true
    }
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      stack.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor)
    ])
  }
}
