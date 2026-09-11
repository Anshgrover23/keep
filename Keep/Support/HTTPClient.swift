import Foundation

/// Bytes over HTTP. `HTTPClient` adds timeouts, retries, and typed errors.
/// Weather never talks to `URLSession` itself.
protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    /// Follows default `URLSession` redirect behavior (no custom delegate).
    /// `HTTPClient` grades the final response, not intermediate redirect hops.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

enum HTTPError: Error, Equatable, LocalizedError {
    case invalidResponse
    case status(code: Int, snippet: String?)
    case timeout
    case cancelled
    case transport(URLError.Code)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid HTTP response"
        case .status(let code, _): "HTTP \(code)"
        case .timeout: "Request timed out"
        case .cancelled: "Request cancelled"
        case .transport(let code): "Transport error (\(code.rawValue))"
        }
    }

    static func mapped(_ error: URLError) -> HTTPError {
        switch error.code {
        case .timedOut: .timeout
        case .cancelled: .cancelled
        default: .transport(error.code)
        }
    }
}

protocol HTTPPerforming: Sendable {
    func get(_ url: URL) async throws -> Data
}

/// GET client with an explicit retry policy. One instance per app; not `URLSession.shared`.
/// Isolation is the actor: mutable stub/exchange state is not marked `@unchecked Sendable`.
actor HTTPClient: HTTPPerforming {
    struct Policy: Equatable, Sendable {
        var requestTimeout: TimeInterval
        var resourceTimeout: TimeInterval
        var waitsForConnectivity: Bool
        var cachePolicy: URLRequest.CachePolicy
        var accept: String
        var maxAttempts: Int
        /// Server errors only (`retryStatusCodes`). Too Many Requests is not retried. Open Meteo is a single idempotent GET and we do not
        /// implement Retry After. Treat Too Many Requests like any other client error until weather actually rate limits us.
        var retryStatusCodes: ClosedRange<Int>
        var retryTransportCodes: Set<URLError.Code>

        static let successStatusRange = 200..<400
        static let serverErrorRange = 500...599
        static let errorSnippetLimit = 80
        static let hangPoll = Duration.milliseconds(10)
        static let productionRequestTimeout: TimeInterval = 20
        static let productionResourceTimeout: TimeInterval = 40
        static let productionMaxAttempts = 2

        static let production = Policy(
            requestTimeout: productionRequestTimeout,
            resourceTimeout: productionResourceTimeout,
            waitsForConnectivity: true,
            cachePolicy: .reloadIgnoringLocalCacheData,
            accept: "application/json",
            maxAttempts: productionMaxAttempts,
            retryStatusCodes: serverErrorRange,
            retryTransportCodes: [
                .timedOut,
                .networkConnectionLost,
                .notConnectedToInternet,
                .cannotFindHost,
                .cannotConnectToHost
            ]
        )

        func shouldRetry(_ error: HTTPError, attemptIndex: Int) -> Bool {
            guard attemptIndex + 1 < maxAttempts else { return false }
            switch error {
            case .cancelled, .invalidResponse:
                return false
            case .timeout:
                return retryTransportCodes.contains(.timedOut)
            case .status(let code, _):
                return retryStatusCodes.contains(code)
            case .transport(let code):
                return retryTransportCodes.contains(code)
            }
        }
    }

    enum Stub: Sendable {
        case response(status: Int, body: Data)
        case urlError(URLError.Code)
        case hangUntilCancelled
    }

    let policy: Policy
    private let transport: any HTTPTransport
    private var stubs: [Stub] = []
    private(set) var lastRequest: URLRequest?
    private(set) var exchangeCount = 0

    init(transport: any HTTPTransport, policy: Policy = .production) {
        self.transport = transport
        self.policy = policy
    }

    static func makeProduction(policy: Policy = .production) -> HTTPClient {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = policy.requestTimeout
        config.timeoutIntervalForResource = policy.resourceTimeout
        config.waitsForConnectivity = policy.waitsForConnectivity
        config.requestCachePolicy = policy.cachePolicy
        config.httpAdditionalHeaders = ["Accept": policy.accept]
        let session = URLSession(configuration: config)
        return HTTPClient(transport: URLSessionTransport(session: session), policy: policy)
    }

    /// Lab / tests: the next `get` consumes these exchanges instead of the network.
    /// Retries never fall through to `URLSession` while a script is active.
    func stubNext(_ stub: Stub) {
        stubs.append(stub)
    }

    func get(_ url: URL) async throws -> Data {
        let request = makeRequest(url)
        lastRequest = request
        exchangeCount = 0
        let script = stubs
        stubs = []

        var attempt = 0
        var scriptIndex = 0
        var lastError: HTTPError?

        while true {
            do {
                try Task.checkCancellation()
                let (data, response) = try await exchange(
                    request: request,
                    script: script,
                    scriptIndex: &scriptIndex,
                    lastError: lastError
                )
                guard let http = response as? HTTPURLResponse else {
                    throw HTTPError.invalidResponse
                }
                guard Policy.successStatusRange.contains(http.statusCode) else {
                    let snippet = String(data: data, encoding: .utf8).map { String($0.prefix(Policy.errorSnippetLimit)) }
                    throw HTTPError.status(code: http.statusCode, snippet: snippet)
                }
                return data
            } catch is CancellationError {
                throw HTTPError.cancelled
            } catch let error as HTTPError {
                if error == .cancelled || !policy.shouldRetry(error, attemptIndex: attempt) {
                    throw error
                }
                lastError = error
                attempt += 1
            } catch let error as URLError {
                let mapped = HTTPError.mapped(error)
                if mapped == .cancelled || !policy.shouldRetry(mapped, attemptIndex: attempt) {
                    throw mapped
                }
                lastError = mapped
                attempt += 1
            } catch {
                throw error
            }
        }
    }

    private func makeRequest(_ url: URL) -> URLRequest {
        var request = URLRequest(
            url: url,
            cachePolicy: policy.cachePolicy,
            timeoutInterval: policy.requestTimeout
        )
        request.httpMethod = "GET"
        request.setValue(policy.accept, forHTTPHeaderField: "Accept")
        return request
    }

    private func exchange(
        request: URLRequest,
        script: [Stub],
        scriptIndex: inout Int,
        lastError: HTTPError?
    ) async throws -> (Data, URLResponse) {
        exchangeCount += 1

        if !script.isEmpty {
            guard scriptIndex < script.count else {
                throw lastError ?? HTTPError.invalidResponse
            }
            let stub = script[scriptIndex]
            scriptIndex += 1
            return try await materialize(stub, url: request.url)
        }

        return try await transport.data(for: request)
    }

    private func materialize(_ stub: Stub, url: URL?) async throws -> (Data, URLResponse) {
        guard let url else { throw HTTPError.invalidResponse }
        switch stub {
        case .response(let status, let body):
            guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
                throw HTTPError.invalidResponse
            }
            return (body, response)
        case .urlError(let code):
            throw URLError(code)
        case .hangUntilCancelled:
            while !Task.isCancelled {
                try await Task.sleep(for: Policy.hangPoll)
            }
            throw CancellationError()
        }
    }
}
