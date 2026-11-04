import FrugaIntegration
import FrugaSDK
import SwiftUI

/// Creates the Home model and connects the screen to the installed clients.
public struct HomeHost: View {
  @State private var model: HomeModel
  @Environment(\.frugaRelayClient) private var relayClient
  @Environment(\.clientsInstalled) private var clientsInstalled

  public init(user: ExampleUser) {
    _model = State(initialValue: HomeModel(user: user))
  }

  public var body: some View {
    HomeScreen(model: model, relayClient: relayClient)
      .onAppear {
        #if DEBUG
        if !clientsInstalled, ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
          assertionFailure("Apply installClients(_:) at the root of the view hierarchy.")
        }
        #endif
      }
  }
}

/// Home: a greeting and the button that opens Relay.
struct HomeScreen: View {
  let model: HomeModel
  let relayClient: FrugaRelayClient

  @ScaledMetric(relativeTo: .body) private var spacing = 16
  @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 56

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: spacing) {
          Image(systemName: "shield.lefthalf.filled")
            .font(.system(size: iconSize))
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
          Text(model.greeting)
            .font(.title2.bold())
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
          Text(HomeText.subtitle)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          Button(action: model.openRelay) {
            Text(HomeText.openRelay)
              .frame(maxWidth: .infinity, minHeight: 44)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          if let message = model.errorMessage {
            ErrorBanner(message: message, onDismiss: model.dismissError)
          }
          Text(HomeText.footnote)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 480)
        .padding()
        .frame(maxWidth: .infinity)
      }
      .navigationTitle(HomeText.title)
      .navigationBarTitleDisplayMode(.inline)
    }
    // Relay is presented with `FrugaRelayView` in a full-screen cover so the balance
    // button can sit over it. When you do not need controls over Relay, use
    // `.frugaRelay(relay, isPresented:onError:)`, which presents the same view.
    .fullScreenCover(isPresented: isRelayPresented) {
      RelayScreen(model: model, relayClient: relayClient)
    }
  }

  private var isRelayPresented: Binding<Bool> {
    Binding(
      get: { model.isRelayPresented },
      set: { isPresented in
        if !isPresented { model.relayDidClose() }
      }
    )
  }
}

/// Relay itself, with a button over it that reads the balance.
private struct RelayScreen: View {
  let model: HomeModel
  let relayClient: FrugaRelayClient

  var body: some View {
    FrugaRelayView(
      relayClient.relay(),
      onError: model.relayDidFail,
      onClose: model.relayDidClose
    )
    .overlay(alignment: .bottom) {
      BalanceOverlay(model: model, relayClient: relayClient)
        .padding()
    }
  }
}

private struct BalanceOverlay: View {
  let model: HomeModel
  let relayClient: FrugaRelayClient

  var body: some View {
    VStack(spacing: 8) {
      if let message = model.balanceMessage {
        Text(message)
          .font(.callout)
          .multilineTextAlignment(.center)
      }
      Button(HomeText.checkBalance) {
        model.requestBalance(using: relayClient)
      }
      .buttonStyle(.bordered)
      .frame(minHeight: 44)
    }
    .padding()
    .frame(maxWidth: 480)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    .onChange(of: model.balanceMessage) { _, message in
      guard let message else { return }
      AccessibilityNotification.Announcement(message).post()
    }
  }
}

private struct ErrorBanner: View {
  let message: String
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      // Red only on the symbol: red body text falls short of 4.5:1 contrast.
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
          .accessibilityHidden(true)
        Text(message)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
      }
      Button(HomeText.dismiss, action: onDismiss)
        .frame(minHeight: 44)
    }
    .accessibilityElement(children: .contain)
  }
}

/// Shown instead of Home when the build settings are incomplete.
public struct ConfigurationProblemScreen: View {
  private let message: String

  public init(error: FrugaConfigurationError) {
    message = HomeText.message(for: error)
  }

  public var body: some View {
    VStack(spacing: 12) {
      Text(HomeText.configurationTitle)
        .font(.title2.bold())
        .accessibilityAddTraits(.isHeader)
      Text(message)
      Text(HomeText.configurationHint)
        .foregroundStyle(.secondary)
    }
    .multilineTextAlignment(.center)
    .padding()
  }
}

#Preview("Home") {
  HomeScreen(model: HomeModel(user: .demo), relayClient: .preview)
}

#Preview("Home with an error") {
  let model = HomeModel(user: .demo)
  model.relayDidFail(FrugaError(code: .offline, message: "offline", recoverable: true))
  return HomeScreen(model: model, relayClient: .preview)
}

#Preview("Configuration problem") {
  ConfigurationProblemScreen(error: .missing(key: FrugaConfiguration.InfoKey.partnerKey))
}
