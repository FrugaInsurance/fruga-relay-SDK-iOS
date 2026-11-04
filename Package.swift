// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "FrugaSDK",
  platforms: [
    .iOS("18.0"),
    .macOS("15.0"),
    .visionOS("2.0")
  ],
  products: [
    .library(name: "FrugaSDK", targets: ["FrugaSDK", "FrugaSDKPlaidLink"])
  ],
  dependencies: [
    .package(url: "https://github.com/plaid/plaid-link-ios-spm.git", exact: "7.2.3")
  ],
  targets: [
    .binaryTarget(
      name: "FrugaSDK",
      url: "https://sdk.fruga.co.uk/apple/0.1.0/FrugaSDK.xcframework.zip",
      checksum: "14f11cdb12c38f178e68079d88b2e82691d07d051aa0094fa4c110de6aee87e7"
    ),
    .target(
      name: "FrugaSDKPlaidLink",
      dependencies: [
        "FrugaSDK",
        .product(
          name: "LinkKit",
          package: "plaid-link-ios-spm",
          condition: .when(platforms: [.iOS])
        )
      ],
      path: "Sources/FrugaSDKPlaidLink"
    )
  ]
)
