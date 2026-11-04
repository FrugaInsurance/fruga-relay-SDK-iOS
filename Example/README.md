# Fruga Apple example

Two small iOS apps that show how to add Fruga Relay to your app: one in
**SwiftUI** (`SwiftUIExample`) and one in **UIKit** (`UIKitExample`). Each shows a
Home screen with an **Open Relay** button; with Relay open, a **Check balance**
button reads the balance through the SDK.

## Requirements

- Xcode 26.4 or later, iOS 18.0 or later.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
- This repository: the example uses the SDK from the folder above it. In your own
  app, add the SDK by repository URL instead.

```bash
xcodegen generate
open FrugaExample.xcodeproj
```

Pick the `SwiftUIExample` or `UIKitExample` scheme and run. The generated
`FrugaExample.xcodeproj` is not committed; run `xcodegen generate` after every pull.

## Add the package

In your project: **File > Add Package Dependencies...**, add the SDK repository and
choose the `FrugaSDK` product. Or in a `Package.swift`:

```swift
.package(url: "<SDK repository>", .upToNextMinor(from: "<version>")),
// target dependency:
.product(name: "FrugaSDK", package: "fruga-relay-SDK-iOS")
```

- Do **not** use "Embed & Sign" for `FrugaSDK`. Xcode embeds it itself; an explicit
  embed fails with "Unexpected duplicate tasks".
- Plaid LinkKit is brought in by the SDK, pinned to exactly **7.2.3**. If your app
  already depends on LinkKit, align it to 7.2.3. No code is needed, but bank linking
  needs [Associated Domains](#associated-domains).

## Keys and configuration

Everything you must set is in `Config/Fruga.xcconfig`:

| Setting | Meaning |
|---|---|
| `FRUGA_PARTNER_KEY` | Partner key issued by Fruga. `YOUR_PARTNER_KEY` is a placeholder: **change it** |
| `FRUGA_API_BASE_URL` | Fruga API base URL, issued by Fruga with your key. `api.example.com` is a placeholder: **change it** |
| `FRUGA_TOKEN_URL` | Endpoint on **your backend** that returns a Fruga access token. `your-backend.example.com` is a placeholder: **change it**, or Relay cannot sign in |
| `FRUGA_LINK_DOMAIN` | The `<partner>.link.fruga.co.uk` subdomain Fruga gives you, for Associated Domains. `YOUR_PARTNER` is a placeholder: **change it** (see below) |
| `FRUGA_SWIFTUI_BUNDLE_ID`, `FRUGA_UIKIT_BUNDLE_ID` | Bundle identifiers |

The values reach the app through `Config/Info.plist` (`$(FRUGA_*)` entries) and are
read once at launch by `FrugaConfiguration` (`Packages/FrugaIntegration`). A missing,
malformed or placeholder value shows a screen naming the Info.plist key to fix. In an xcconfig file
`//` starts a comment, so URLs are written `https:/$()/host`.

The projects carry no development team. To run on a device, choose your team under
Signing & Capabilities and change the bundle identifiers to ids you own.

## Backend token contract

The SDK asks your app for a token through a token provider, with a reason:

| Reason | When |
|---|---|
| `.initial` | first use |
| `.ttl` | the token's lifetime is about to end |
| `.unauthorized` | Fruga rejected the current token |

Rules for the provider (`TokenClient` in `Packages/FrugaIntegration`):

- It must return a **fresh** token every time it is called, for every reason.
- The SDK gives it **30 seconds**. If it throws or is too slow, Relay reports
  `FrugaError.Code.tokenProviderFailed`.
- This example sends `POST <FRUGA_TOKEN_URL>` with `{ "userRef": "<your user id>" }`
  and expects `{ "accessToken": "..." }`. The request times out after 25 seconds,
  inside the SDK's 30.
- **The partner secret that signs tokens stays on your server.**
- **Your backend must identify the user from your app's own authenticated session**
  (your session cookie or bearer token), and must not trust a `userRef` sent by the
  client. Otherwise anyone who can call the endpoint can get a token for any user.
- To send your session credential, pass `authorization:` to `TokenClient.live`. It
  runs before every request and returns the `Authorization` header value:

```swift
let tokenClient = TokenClient.live(
  configuration: configuration,
  userRef: user.userRef,
  authorization: { "Bearer \(try await auth.currentAccessToken())" }
)
```

## SwiftUI path

1. `AppComposition` (`SwiftUIExample/`) builds `FrugaConfiguration`, a `TokenClient`
   and a `FrugaRelayClient`. It is the only place real clients are created.
2. The app root applies `.installClients(...)`, putting them in the SwiftUI
   environment.
3. `HomeHost` creates the Home model; its button flips `isRelayPresented`.
4. The Home screen presents Relay full screen. The one-line version is
   `.frugaRelay(relay, isPresented: $isPresented, onError: { ... })`. This example
   presents `FrugaRelayView` itself in a `fullScreenCover`, which is what that
   modifier does, so it can put the balance button over Relay.

## UIKit path

1. `AppComposition` (`UIKitExample/`) builds the same clients and hands them to
   `HomeViewController` through its initializer.
2. `HomeViewController` opens Relay with
   `relay.present(from: self, onError: { ... })`. **Present Relay; never push it** onto
   a navigation stack. It is a full-screen modal.
3. The model is observable. `ObservationLoop` re-reads it when it changes and is
   stopped when the screen disappears.
4. When Home appears again after Relay closed, it tells the model Relay is gone.

## Reading the balance

`FrugaRelay.getBalance()` only works **while a Relay screen is open**. With none
open it fails at once with `bridgeTimeout`. That is why the **Check balance** button
sits on top of Relay (`BalanceOverlayView` in UIKit, `BalanceOverlay` in SwiftUI)
and not on Home.

## Relay instances and options

One `FrugaRelay` is one Relay screen and one presentation path. Keep a single instance
(`RelayHolder`) and present it from one place. Options (`FrugaRelayOptions`) are fixed
when the relay is created: to change them, create a new `FrugaRelay` and stop using
the old one. If the old one is still on screen, call its `close()` first, which
dismisses it. This example never changes options, so it never does either.

## Errors

Relay reports problems as `FrugaError` with a `code`, a technical `message` and a
`recoverable` flag. `HomeText.message(for:)` maps each `FrugaError.Code` to a user
message and adds "Try again." when `recoverable` is true. Show your own copy, not the
technical `message`.

## Logging

The SDK logs through `os.Logger` with secrets redacted; nothing is needed. To
forward Relay's log lines to your own system, set `logger` on the relay to a type
that conforms to `FrugaLogger`. Set it where the relay is created: in this example,
the `makeRelay` closure of `FrugaRelayClient.live`, right after `FrugaRelay(...)`:

```swift
struct ForwardingLogger: FrugaLogger {
  func log(level: FrugaLogLevel, event: String, data: [String: String]) {
    MyAnalytics.record(level: level.rawValue, event: event, data: data)
  }
}

// Packages/FrugaIntegration/Sources/FrugaIntegration/FrugaRelayClient.swift
RelayHolder(makeRelay: {
  let relay = FrugaRelay(partnerKey: configuration.partnerKey, tokenProvider: tokenClient.token, options: options)
  relay.logger = ForwardingLogger()
  return relay
})
```

## Associated Domains

Both apps declare `applinks:` for `FRUGA_LINK_DOMAIN`
(`Config/*.entitlements`). Banks that use OAuth return to your app through this
Universal Link. Fruga hosts the `apple-app-site-association` file for your subdomain.
The value in `Config/Fruga.xcconfig`, `YOUR_PARTNER.link.fruga.co.uk`, is a placeholder.
Before you use it:

1. Give Fruga your Team ID and bundle identifier, so Fruga can list your app in that file.
2. Set `FRUGA_LINK_DOMAIN` to the `<partner>.link.fruga.co.uk` subdomain Fruga gives you.
3. Use the same team and bundle identifier in Xcode (Signing & Capabilities).

Plaid LinkKit picks up that return by itself: do not route `*.link.fruga.co.uk` user
activities in your scene or app delegate. While testing before the file is live, you
can add `?mode=developer` to the entry. Remove it before you ship.

## Tests and layout

```
Config/                    xcconfig, Info.plist, entitlements
Packages/FrugaIntegration  configuration, token client, relay holder and client (no UI)
Packages/FrugaExampleUI    Home model, text, SwiftUI Home screen, environment clients
SwiftUIExample/            app entry point, composition
UIKitExample/              app delegate, scene delegate, composition, Home, overlay
FrugaExample.xctestplan    package tests plus both apps' tests
```

```bash
xcodebuild test -project FrugaExample.xcodeproj -scheme SwiftUIExample \
  -testPlan FrugaExample -destination "id=<simulator id>"
```

## Before you share or ship

- Replace the placeholder values in `Config/Fruga.xcconfig` with your own, and point
  `FRUGA_TOKEN_URL` at your own backend.
- Switch the SDK dependency from the local path (`..` in `project.yml`, `../../..`
  in the package manifests) to the remote repository URL.
- Set `FRUGA_LINK_DOMAIN` to your Fruga subdomain, confirm Fruga has your Team ID and
  bundle identifier, and remove any `?mode=developer`.
