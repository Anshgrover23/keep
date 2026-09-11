import Foundation
import Testing
@testable import Keep

@MainActor
@Suite(.serialized)
struct WeatherHTTPBoundaryTests {
    @Test func successfulForecastMapsWMOCodeAndClearsError() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: true)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 19, longitude: 72, force: true)
        #expect(weather.kind == .rain)
        #expect(weather.lastWMOCode == 61)
        #expect(weather.lastError == nil)
        #expect(weather.lastUpdated != nil)
    }

    @Test func extraUnknownFieldsDoNotFailDecoding() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: true)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .rain)
        #expect(weather.lastError == nil)
    }

    @Test func missingWeatherCodeIsMalformedResponse() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: Data(#"{"current":{}}"#.utf8)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .clear)
        #expect(weather.lastError == "Malformed weather response")
        #expect(
            WeatherStatus.resolve(
                lastUpdated: weather.lastUpdated,
                lastError: weather.lastError,
                fix: .gps(latitude: 19, longitude: 72)
            ) == .unavailable
        )
    }

    @Test func malformedJSONIsSurfacedWithoutChangingKind() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: Data("{".utf8)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .clear)
        #expect(weather.lastError == "Malformed weather response")
        #expect(
            WeatherStatus.resolve(
                lastUpdated: weather.lastUpdated,
                lastError: weather.lastError,
                fix: .gps(latitude: 19, longitude: 72)
            ) == .unavailable
        )
    }

    @Test func http503AfterSuccessLeavesKindAndMarksStale() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: false)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .rain)

        await client.stubNext(.response(status: 503, body: Data("down".utf8)))
        await client.stubNext(.response(status: 503, body: Data("down".utf8)))
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .rain)
        #expect(weather.lastError == "HTTP 503")
        #expect(
            WeatherStatus.resolve(
                lastUpdated: weather.lastUpdated,
                lastError: weather.lastError,
                fix: .gps(latitude: 19, longitude: 72)
            ) == .stale
        )
    }

    @Test func malformedAfterSuccessLeavesKindAndMarksStale() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: false)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        await client.stubNext(.response(status: 200, body: Data("{".utf8)))
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .rain)
        #expect(
            WeatherStatus.resolve(
                lastUpdated: weather.lastUpdated,
                lastError: weather.lastError,
                fix: .gps(latitude: 19, longitude: 72)
            ) == .stale
        )
    }

    @Test func timeZoneFixIsApproximateEvenAfterSuccess() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: false)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 0, longitude: 75, force: true)
        #expect(weather.kind == .rain)
        #expect(
            WeatherStatus.resolve(
                lastUpdated: weather.lastUpdated,
                lastError: weather.lastError,
                fix: .timeZone(longitude: 75)
            ) == .approximate
        )
        #expect(WeatherStatus.approximate.extraLine == "Weather is approximate")
    }

    @Test func gpsSuccessIsAvailable() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: false)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 19, longitude: 72, force: true)
        #expect(
            WeatherStatus.resolve(
                lastUpdated: weather.lastUpdated,
                lastError: weather.lastError,
                fix: .gps(latitude: 19, longitude: 72)
            ) == .available
        )
        #expect(WeatherStatus.available.extraLine == nil)
    }

    @Test func http404DoesNotRetryAndDoesNotChangeKind() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 404, body: Data("nope".utf8)))
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: false)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .clear)
        #expect(weather.lastError == "HTTP 404")
        #expect(await client.exchangeCount == 1)
    }

    @Test func http503RetriesThenRecovers() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.response(status: 503, body: Data("down".utf8)))
        await client.stubNext(.response(status: 200, body: rainJSON(extraFields: false)))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .rain)
        #expect(weather.lastError == nil)
        #expect(await client.exchangeCount == 2)
    }

    @Test func labFailureUsesHTTPClient503AndDoesNotCallNetwork() async {
        let client = HTTPClient(transport: RejectingTransport())
        let weather = WeatherService(client: client)
        await weather.failNextRefresh()
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.kind == .clear)
        #expect(weather.lastError == "HTTP 503")
        #expect(await client.exchangeCount == 2)
    }

    @Test func timeoutSurfacesTypedError() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.urlError(.timedOut))
        await client.stubNext(.urlError(.timedOut))
        let weather = WeatherService(client: client)
        await weather.refresh(latitude: 1, longitude: 2, force: true)
        #expect(weather.lastError == "Request timed out")
    }

    @Test func cancellationDoesNotRetryOrOverwriteWeather() async {
        let client = HTTPClient(transport: RejectingTransport())
        await client.stubNext(.hangUntilCancelled)
        let weather = WeatherService(client: client)
        let task = Task {
            await weather.refresh(latitude: 1, longitude: 2, force: true)
        }
        try? await Task.sleep(for: .milliseconds(30))
        task.cancel()
        await task.value
        #expect(weather.kind == .clear)
        #expect(weather.lastError == nil)
        #expect(await client.exchangeCount == 1)
    }
}

private func rainJSON(extraFields: Bool) -> Data {
    if extraFields {
        Data(#"{"current":{"weather_code":61,"temperature_2m":22.5},"unused":true}"#.utf8)
    } else {
        Data(#"{"current":{"weather_code":61}}"#.utf8)
    }
}

private struct RejectingTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        Issue.record("WeatherService used the network: \(request.url?.absoluteString ?? "")")
        throw URLError(.notConnectedToInternet)
    }
}
