import Foundation
import Testing
@testable import Keep

struct HTTPRetryPolicyTests {
    @Test func retriesOnlyTransientFailuresWithinMaxAttempts() {
        let policy = HTTPClient.Policy.production
        #expect(policy.shouldRetry(.status(code: 503, snippet: nil), attemptIndex: 0))
        #expect(policy.shouldRetry(.status(code: 503, snippet: nil), attemptIndex: 1) == false)
        #expect(policy.shouldRetry(.status(code: 404, snippet: nil), attemptIndex: 0) == false)
        #expect(policy.shouldRetry(.status(code: 429, snippet: nil), attemptIndex: 0) == false)
        #expect(policy.shouldRetry(.timeout, attemptIndex: 0))
        #expect(policy.shouldRetry(.transport(.cannotConnectToHost), attemptIndex: 0))
        #expect(policy.shouldRetry(.cancelled, attemptIndex: 0) == false)
        #expect(policy.shouldRetry(.invalidResponse, attemptIndex: 0) == false)
        #expect(policy.shouldRetry(.transport(.userAuthenticationRequired), attemptIndex: 0) == false)
    }
}

struct HTTPErrorDescriptionTests {
    @Test func preservesStatusCodeInMessage() {
        #expect(HTTPError.status(code: 503, snippet: "lab").errorDescription == "HTTP 503")
        #expect(HTTPError.timeout.errorDescription == "Request timed out")
        #expect(HTTPError.cancelled.errorDescription == "Request cancelled")
        #expect(HTTPError.invalidResponse.errorDescription == "Invalid HTTP response")
    }
}

@Suite(.serialized)
struct HTTPClientBoundaryTests {
    private let url = URL(string: "https://example.test/weather")!

    @Test func successfulResponseReturnsBodyAndRecordsGETConfiguration() async throws {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: Data("ok".utf8)))
        let data = try await client.get(url)
        #expect(String(data: data, encoding: .utf8) == "ok")
        #expect(await client.exchangeCount == 1)
        let request = try #require(await client.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == HTTPClient.Policy.production.requestTimeout)
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(request.url == url)
    }

    @Test func invalidNonHTTPResponseIsTypedError() async {
        let client = HTTPClient(transport: InvalidResponseTransport())
        await #expect(throws: HTTPError.invalidResponse) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 1)
    }

    @Test func rateLimit429IsNotRetried() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 429, body: Data("slow".utf8)))
        await client.stubNext(.response(status: 200, body: Data("should not run".utf8)))
        await #expect(throws: HTTPError.status(code: 429, snippet: "slow")) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 1)
    }

    @Test func clientError4xxIsNotRetried() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 404, body: Data("missing".utf8)))
        await client.stubNext(.response(status: 200, body: Data("should not run".utf8)))
        await #expect(throws: HTTPError.status(code: 404, snippet: "missing")) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 1)
    }

    @Test func serverError5xxRetriesThenSucceeds() async throws {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 503, body: Data("err".utf8)))
        await client.stubNext(.response(status: 200, body: Data("ok".utf8)))
        let data = try await client.get(url)
        #expect(String(data: data, encoding: .utf8) == "ok")
        #expect(await client.exchangeCount == 2)
    }

    @Test func serverError5xxRetriesThenFailsWithoutHittingNetwork() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 503, body: Data("down".utf8)))
        await #expect(throws: HTTPError.status(code: 503, snippet: "down")) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 2)
    }

    @Test func timeoutIsRetriedThenSurfaced() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.urlError(.timedOut))
        await client.stubNext(.urlError(.timedOut))
        await #expect(throws: HTTPError.timeout) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 2)
    }

    @Test func transientTransportFailureRetriesThenSucceeds() async throws {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.urlError(.cannotConnectToHost))
        await client.stubNext(.response(status: 200, body: Data("ok".utf8)))
        let data = try await client.get(url)
        #expect(String(data: data, encoding: .utf8) == "ok")
        #expect(await client.exchangeCount == 2)
    }

    @Test func cancellationIsNotRetried() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.hangUntilCancelled)
        let task = Task { try await client.get(url) }
        try? await Task.sleep(for: .milliseconds(30))
        task.cancel()
        await #expect(throws: HTTPError.cancelled) {
            _ = try await task.value
        }
        #expect(await client.exchangeCount == 1)
    }

    @Test func urlErrorCancelledIsNotRetried() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.urlError(.cancelled))
        await client.stubNext(.response(status: 200, body: Data("nope".utf8)))
        await #expect(throws: HTTPError.cancelled) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 1)
    }
}

/// Fails if the client falls through to the network.
private struct RejectingTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        Issue.record("HTTPClient used the network: \(request.url?.absoluteString ?? "")")
        throw URLError(.notConnectedToInternet)
    }
}

private struct InvalidResponseTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        (Data(), URLResponse())
    }
}
