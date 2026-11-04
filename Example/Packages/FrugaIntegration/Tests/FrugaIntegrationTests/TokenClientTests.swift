import Foundation
import FrugaSDK
import Synchronization
import Testing

@testable import FrugaIntegration

/// Serialized: the stubbed URL protocol is shared by every test in the suite.
@Suite(.serialized, .timeLimit(.minutes(1)))
struct TokenClientTests {
  private let configuration = FrugaConfiguration(
    partnerKey: "pk_test",
    apiBaseURL: URL(string: "https://api.example.com")!,
    tokenURL: URL(string: "https://backend.example.com/api/fruga/assertion")!
  )

  private func respond(status: Int, body: String) -> MockURLProtocol.Handler {
    { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
      return (response, Data(body.utf8))
    }
  }

  @Test(arguments: [FrugaTokenRequestReason.initial, .ttl, .unauthorized])
  func postsTheUserRefAndReturnsTheToken(reason: FrugaTokenRequestReason) async throws {
    let captured = CapturedRequest()
    MockURLProtocol.setHandler { request in
      captured.store(request)
      return try respond(status: 200, body: #"{"accessToken":"abc123"}"#)(request)
    }
    defer { MockURLProtocol.setHandler(nil) }

    let client = TokenClient.live(
      configuration: configuration,
      userRef: "user-1",
      session: MockURLProtocol.makeSession()
    )
    let token = try await client.token(reason)

    #expect(token == "abc123")
    let request = try #require(captured.value)
    #expect(request.httpMethod == "POST")
    #expect(request.url == configuration.tokenURL)
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    let body = try #require(captured.body)
    #expect(try JSONDecoder().decode([String: String].self, from: body) == ["userRef": "user-1"])
    #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    #expect(request.timeoutInterval == TokenClient.requestTimeout)
  }

  @Test func sendsTheSessionCredentialOnEveryRequest() async throws {
    let captured = CapturedRequest()
    MockURLProtocol.setHandler { request in
      captured.store(request)
      return try respond(status: 200, body: #"{"accessToken":"abc123"}"#)(request)
    }
    defer { MockURLProtocol.setHandler(nil) }

    let sessions = SessionTokens()
    let client = TokenClient.live(
      configuration: configuration,
      userRef: "user-1",
      authorization: { "Bearer \(sessions.next())" },
      session: MockURLProtocol.makeSession()
    )
    _ = try await client.token(.initial)
    #expect(captured.value?.value(forHTTPHeaderField: "Authorization") == "Bearer session-1")
    _ = try await client.token(.ttl)
    #expect(captured.value?.value(forHTTPHeaderField: "Authorization") == "Bearer session-2")
  }

  @Test func doesNotCallTheBackendWhenTheCredentialFails() async {
    let captured = CapturedRequest()
    MockURLProtocol.setHandler { request in
      captured.store(request)
      return try respond(status: 200, body: #"{"accessToken":"abc123"}"#)(request)
    }
    defer { MockURLProtocol.setHandler(nil) }

    let client = TokenClient.live(
      configuration: configuration,
      userRef: "u",
      authorization: { throw TokenClientError.unimplemented },
      session: MockURLProtocol.makeSession()
    )
    await #expect(throws: TokenClientError.unimplemented) { try await client.token(.initial) }
    #expect(captured.value == nil)
  }

  @Test func throwsOnANon2xxStatus() async {
    MockURLProtocol.setHandler(respond(status: 401, body: "{}"))
    defer { MockURLProtocol.setHandler(nil) }
    let client = TokenClient.live(configuration: configuration, userRef: "u", session: MockURLProtocol.makeSession())
    await #expect(throws: TokenClientError.httpStatus(401)) { try await client.token(.initial) }
  }

  @Test(arguments: [#"{"other":1}"#, "not json", #"{"accessToken":42}"#])
  func throwsOnAMalformedBody(body: String) async {
    MockURLProtocol.setHandler(respond(status: 200, body: body))
    defer { MockURLProtocol.setHandler(nil) }
    let client = TokenClient.live(configuration: configuration, userRef: "u", session: MockURLProtocol.makeSession())
    await #expect(throws: TokenClientError.invalidResponse) { try await client.token(.ttl) }
  }

  @Test func throwsOnAnEmptyToken() async {
    MockURLProtocol.setHandler(respond(status: 200, body: #"{"accessToken":""}"#))
    defer { MockURLProtocol.setHandler(nil) }
    let client = TokenClient.live(configuration: configuration, userRef: "u", session: MockURLProtocol.makeSession())
    await #expect(throws: TokenClientError.missingAccessToken) { try await client.token(.unauthorized) }
  }

  @Test func throwsOnATransportFailure() async {
    MockURLProtocol.setHandler { _ in throw URLError(.notConnectedToInternet) }
    defer { MockURLProtocol.setHandler(nil) }
    let client = TokenClient.live(configuration: configuration, userRef: "u", session: MockURLProtocol.makeSession())
    await #expect(throws: URLError.self) { try await client.token(.initial) }
  }

  @Test func previewReturnsAPlaceholder() async throws {
    #expect(try await TokenClient.preview.token(.initial) == "preview-token")
  }

  @Test func failingThrows() async {
    await #expect(throws: TokenClientError.unimplemented) { try await TokenClient.failing.token(.initial) }
  }
}

/// Hands out a new session token on every call, like a session that refreshes.
private final class SessionTokens: Sendable {
  private let count = Mutex(0)

  func next() -> String {
    count.withLock { value in
      value += 1
      return "session-\(value)"
    }
  }
}

/// Records the request the stubbed protocol received. A body set on `URLRequest`
/// reaches a `URLProtocol` as a stream, so it is read out here.
private final class CapturedRequest: Sendable {
  private let state = Mutex<(request: URLRequest, body: Data)?>(nil)

  var value: URLRequest? { state.withLock { $0?.request } }
  var body: Data? { state.withLock { $0?.body } }

  func store(_ request: URLRequest) {
    var data = Data()
    if let stream = request.httpBodyStream {
      stream.open()
      defer { stream.close() }
      var buffer = [UInt8](repeating: 0, count: 1_024)
      while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        if count <= 0 { break }
        data.append(buffer, count: count)
      }
    }
    state.withLock { $0 = (request, data) }
  }
}
