import Combine
import Foundation

@MainActor
final class WeatherService: ObservableObject, WeatherFetching {
    @Published private(set) var kind: WeatherKind = .clear
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var lastWMOCode: Int?

    static let minimumRefreshInterval: TimeInterval = .minutes(1)
    static let significantMoveDegrees = 0.05
    static let labInjectedFailureStatus = 503

    private let client: HTTPClient
    private var lastFetch: Date?
    private var lastLatitude: Double?
    private var lastLongitude: Double?

    init(client: HTTPClient) {
        self.client = client
    }

    func failNextRefresh() async {
        await client.stubNext(.response(status: Self.labInjectedFailureStatus, body: Data("lab injected".utf8)))
    }

    func refresh(latitude: Double, longitude: Double, force: Bool = false) async {
        if !force, !shouldFetch(latitude: latitude, longitude: longitude) {
            return
        }
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "weather_code"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components?.url else { return }
        let refresh = KeepLog.weatherSignpost.beginInterval("refresh")
        defer { KeepLog.weatherSignpost.endInterval("refresh", refresh) }
        do {
            let data = try await client.get(url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            kind = WeatherKind(wmoCode: decoded.current.weather_code)
            lastWMOCode = decoded.current.weather_code
            lastUpdated = Date()
            lastFetch = Date()
            lastLatitude = latitude
            lastLongitude = longitude
            lastError = nil
            KeepLog.weather.info("Weather \(self.kind.rawValue, privacy: .public) wmo=\(decoded.current.weather_code)")
        } catch is CancellationError {
            return
        } catch let error as HTTPError where error == .cancelled {
            return
        } catch let error as HTTPError {
            lastError = error.errorDescription
            KeepLog.weather.error("Weather fetch failed: \(error.errorDescription ?? "", privacy: .public)")
        } catch is DecodingError {
            lastError = "Malformed weather response"
            KeepLog.weather.error("Malformed weather response")
        } catch {
            lastError = error.localizedDescription
            KeepLog.weather.error("Weather fetch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func shouldFetch(latitude: Double, longitude: Double) -> Bool {
        if let lastLatitude, let lastLongitude {
            let moved = hypot(latitude - lastLatitude, longitude - lastLongitude)
            if moved > Self.significantMoveDegrees { return true }
        }
        guard let lastFetch else { return true }
        return Date().timeIntervalSince(lastFetch) >= Self.minimumRefreshInterval
    }
}

struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        var weather_code: Int
    }

    var current: Current
}
