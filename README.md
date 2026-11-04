# Fruga Apple SDK

Swift package for the Fruga Relay SDK on iOS 18+, macOS 15+ and visionOS 2+.

Full guide: [docs.fruga.co.uk](https://docs.fruga.co.uk/relay/sdks/ios/overview).

## Requirements

- iOS 18, iPadOS 18, macOS 15 or visionOS 2 as the deployment target.
- Xcode 26.4 or later.
- A partner key from Fruga.
- An endpoint on your backend that returns a Fruga access token. See
  [Authentication](https://docs.fruga.co.uk/relay/guides/auth).
- For bank linking on iOS, the Associated Domains capability. See
  [Open banking](https://docs.fruga.co.uk/relay/sdks/ios/integration-guide#open-banking-plaid-link).

## Install

```swift
dependencies: [
  .package(url: "https://github.com/FrugaInsurance/fruga-relay-SDK-iOS", .upToNextMinor(from: "0.1.0"))
],
targets: [
  .target(name: "App", dependencies: [
    .product(name: "FrugaSDK", package: "fruga-relay-SDK-iOS")
  ])
]
```

In Xcode: **File › Add Package Dependencies…**, add this repo, and pick the
`FrugaSDK` product. While the SDK is 0.x, use "Up to Next Minor Version":
a 0.x minor release may contain breaking changes. Do **not** choose "Embed & Sign"
(or `embed:`) for it: Xcode embeds the package framework itself, and an explicit
embed fails with "Unexpected duplicate tasks".

## Quick start

Create one `FrugaRelay` per signed-in session and keep it alive. The token provider
asks your backend for a Fruga access token.

```swift
import FrugaSDK

let fruga = FrugaRelay(
  partnerKey: "YOUR_PARTNER_KEY",
  tokenProvider: { reason in try await Backend.frugaToken(reason: reason) },
  options: FrugaRelayOptions(tokenTtlSeconds: 900)
)
```

SwiftUI:

```swift
Button("Open Relay") { isRelayPresented = true }
  .frugaRelay(fruga, isPresented: $isRelayPresented, onError: { error in /* ... */ })
```

UIKit:

```swift
fruga.present(from: self, onError: { error in /* ... */ })
```

## Plaid Link

The `FrugaSDK` product depends on Plaid's
[`plaid-link-ios-spm`](https://github.com/plaid/plaid-link-ios-spm) at exactly
**7.2.3**, on iOS only. If your app already depends on LinkKit, align it to
7.2.3. No code is needed, but bank linking needs
[Associated Domains](https://docs.fruga.co.uk/relay/sdks/ios/integration-guide#open-banking-plaid-link).
Plaid Link is not available on macOS or visionOS.

## Example

`Example/` contains a SwiftUI and a UIKit app that integrate the SDK. See
[`Example/README.md`](Example/README.md).

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
and is not committed. If `Example/FrugaExample.xcodeproj` is missing, or after you
pull changes, generate it:

```bash
brew install xcodegen   # if you don't have it
cd Example
xcodegen generate
open FrugaExample.xcodeproj
```

## License

See [LICENSE](LICENSE). Use of the SDK requires an agreement with Fruga Limited.
