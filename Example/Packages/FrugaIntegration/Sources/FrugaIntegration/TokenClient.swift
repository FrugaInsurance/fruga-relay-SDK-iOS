import Foundation
import FrugaSDK

/// Fetches Fruga access tokens from your backend.
///
/// The SDK calls its token provider whenever it needs a token: on first use
/// (`.initial`), when the token's lifetime elapses (`.ttl`), and when Fruga
/// rejects the current one (`.unauthorized`). Every call must return a fresh
/// token, and the SDK gives each call 30 seconds. The partner secret that signs
/// the token stays on your server, and your server decides which user the
/// token is for from the app's own signed-in session.
public struct TokenClient: Sendable {
  public var token: @Sendable (FrugaTokenRequestReason) async throws -> String

  public init(token: @escaping @Sendable (FrugaTokenRequestReason) async throws -> String) {
    self.token = token
  }
}

public enum TokenClientError: Error, Equatable, Sendable {
  /// The backend answered with a status outside 200-299.
  case httpStatus(Int)
  /// The response body was not the expected JSON object.
  case invalidResponse
  /// The response carried an empty `accessToken`.
  case missingAccessToken
  /// A ``TokenClient/failing`` client was used.
  case unimplemented
}

extension TokenClient {
  /// Seconds a token request may take. The SDK waits 30 seconds for the
  /// provider, so the request gives up first and reports its own error.
  static let requestTimeout: TimeInterval = 25

  /// Posts `{ "userRef": ... }` to ``FrugaConfiguration/tokenURL`` and returns
  /// the `accessToken` of the JSON response. Throwing makes the SDK report
  /// `FrugaError.Code.tokenProviderFailed`.
  ///
  /// - Parameters:
  ///   - userRef: Your identifier for the signed-in user. Your backend must not
  ///     trust it on its own; identify the user from your app's session.
  ///   - authorization: Returns the `Authorization` header value that proves to
  ///     your backend who the signed-in user is, such as `"Bearer <session token>"`.
  ///     It runs before every request, so a refreshed session is picked up.
  ///     `nil` sends no header.
  public static func live(
    configuration: FrugaConfiguration,
    userRef: String,
    authorization: @escaping @Sendable () async throws -> String? = { nil },
    session: URLSession = .shared
  ) -> TokenClient {
    let url = configuration.tokenURL
    return TokenClient { _ in
      var request = URLRequest(url: url, timeoutInterval: requestTimeout)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      if let credential = try await authorization() {
        request.setValue(credential, forHTTPHeaderField: "Authorization")
      }
      request.httpBody = try JSONEncoder().encode(Request(userRef: userRef))

      let (data, response) = try await session.data(for: request)
      let status = (response as? HTTPURLResponse)?.statusCode ?? 0
      guard (200..<300).contains(status) else { throw TokenClientError.httpStatus(status) }
      let body: Response
      do {
        body = try JSONDecoder().decode(Response.self, from: data)
      } catch is DecodingError {
        throw TokenClientError.invalidResponse
      }
      guard !body.accessToken.isEmpty else { throw TokenClientError.missingAccessToken }
      return body.accessToken
    }
  }

  /// Returns a fixed placeholder token without any network access.
  public static var preview: TokenClient {
    TokenClient { _ in "preview-token" }
  }

  /// Throws ``TokenClientError/unimplemented`` on every call.
  public static var failing: TokenClient {
    TokenClient { _ in throw TokenClientError.unimplemented }
  }

  private struct Request: Encodable {
    let userRef: String
  }

  private struct Response: Decodable {
    let accessToken: String
  }
}
