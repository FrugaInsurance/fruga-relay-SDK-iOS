// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "FrugaIntegration",
  defaultLocalization: "en",
  platforms: [.iOS("18.0")],
  products: [
    .library(name: "FrugaIntegration", targets: ["FrugaIntegration"])
  ],
  dependencies: [
    .package(name: "FrugaSDK", path: "../../..")
  ],
  targets: [
    .target(
      name: "FrugaIntegration",
      dependencies: [.product(name: "FrugaSDK", package: "FrugaSDK")],
      swiftSettings: [.treatAllWarnings(as: .error)]
    ),
    .testTarget(
      name: "FrugaIntegrationTests",
      dependencies: ["FrugaIntegration"],
      swiftSettings: [.treatAllWarnings(as: .error)]
    )
  ],
  swiftLanguageModes: [.v6]
)
