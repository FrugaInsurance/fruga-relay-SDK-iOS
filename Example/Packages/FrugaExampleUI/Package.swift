// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "FrugaExampleUI",
  defaultLocalization: "en",
  platforms: [.iOS("18.0")],
  products: [
    .library(name: "FrugaExampleUI", targets: ["FrugaExampleUI"])
  ],
  dependencies: [
    .package(path: "../FrugaIntegration"),
    .package(name: "FrugaSDK", path: "../../..")
  ],
  targets: [
    .target(
      name: "FrugaExampleUI",
      dependencies: [
        "FrugaIntegration",
        .product(name: "FrugaSDK", package: "FrugaSDK")
      ],
      resources: [.process("Resources")],
      swiftSettings: [.treatAllWarnings(as: .error)]
    ),
    .testTarget(
      name: "FrugaExampleUITests",
      dependencies: ["FrugaExampleUI"],
      swiftSettings: [.treatAllWarnings(as: .error)]
    )
  ],
  swiftLanguageModes: [.v6]
)
