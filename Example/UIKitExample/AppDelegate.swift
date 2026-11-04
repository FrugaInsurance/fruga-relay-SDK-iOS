import UIKit

/// Apps built with the current iOS SDK must use the scene life cycle, so the
/// window is created by `SceneDelegate`. The configuration is set up in code,
/// which keeps one Info.plist for both example apps.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }
}
