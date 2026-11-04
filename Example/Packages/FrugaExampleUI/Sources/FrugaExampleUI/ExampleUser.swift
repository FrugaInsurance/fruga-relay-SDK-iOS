/// The signed-in user of the host app.
///
/// `userRef` is your own identifier for the user. Your backend must work out
/// the user from your app's own signed-in session, not from this value alone.
public struct ExampleUser: Sendable, Equatable {
  public let userRef: String
  public let displayName: String

  public init(userRef: String, displayName: String) {
    self.userRef = userRef
    self.displayName = displayName
  }

  /// A placeholder user. Use your app's signed-in user instead.
  public static let demo = ExampleUser(userRef: "user-123", displayName: "Alex Example")
}
