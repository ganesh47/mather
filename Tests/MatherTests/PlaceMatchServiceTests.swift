import CoreLocation
import Testing
@testable import Mather

struct PlaceMatchServiceTests {

    // MARK: - GPS evaluation

    @Test
    func gpsMatchWithinMatchRadius() {
        // Two locations 10 metres apart — well inside 15 m match threshold
        let result = PlaceMatchService.evaluate(
            savedLatitude: 51.5074,
            savedLongitude: -0.1278,
            savedGPSAccuracy: 5.0,
            currentLocation: CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 51.5074 + 0.00009,   // ~10 m north
                    longitude: -0.1278
                ),
                altitude: 0,
                horizontalAccuracy: 5.0,
                verticalAccuracy: -1,
                timestamp: .now
            ),
            savedImageData: nil,
            candidateImageData: nil
        )
        #expect(result.result == .match)
        #expect(result.wasGPS == true)
    }

    @Test
    func gpsCloseInCloseRange() {
        // ~25 m apart — between 15 m match and 30 m close thresholds
        let result = PlaceMatchService.evaluate(
            savedLatitude: 51.5074,
            savedLongitude: -0.1278,
            savedGPSAccuracy: 5.0,
            currentLocation: CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 51.5074 + 0.000225,   // ~25 m north
                    longitude: -0.1278
                ),
                altitude: 0,
                horizontalAccuracy: 5.0,
                verticalAccuracy: -1,
                timestamp: .now
            ),
            savedImageData: nil,
            candidateImageData: nil
        )
        #expect(result.result == .close)
        #expect(result.wasGPS == true)
    }

    @Test
    func gpsNoMatchBeyondCloseRange() {
        // ~100 m apart — beyond 30 m close threshold
        let result = PlaceMatchService.evaluate(
            savedLatitude: 51.5074,
            savedLongitude: -0.1278,
            savedGPSAccuracy: 5.0,
            currentLocation: CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 51.5074 + 0.0009,   // ~100 m north
                    longitude: -0.1278
                ),
                altitude: 0,
                horizontalAccuracy: 5.0,
                verticalAccuracy: -1,
                timestamp: .now
            ),
            savedImageData: nil,
            candidateImageData: nil
        )
        #expect(result.result == .noMatch)
    }

    @Test
    func gpsIgnoredWhenAccuracyTooWeak() {
        // GPS accuracy 50 m — above the 20 m cutoff, should be discarded
        let result = PlaceMatchService.evaluate(
            savedLatitude: 51.5074,
            savedLongitude: -0.1278,
            savedGPSAccuracy: 50.0,
            currentLocation: CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 51.5074 + 0.00009,
                    longitude: -0.1278
                ),
                altitude: 0,
                horizontalAccuracy: 50.0,
                verticalAccuracy: -1,
                timestamp: .now
            ),
            savedImageData: nil,
            candidateImageData: nil
        )
        // No image data either → noMatch, wasGPS false
        #expect(result.result == .noMatch)
        #expect(result.wasGPS == false)
    }

    @Test
    func noMatchWhenBothSignalsMissing() {
        let result = PlaceMatchService.evaluate(
            savedLatitude: nil,
            savedLongitude: nil,
            savedGPSAccuracy: nil,
            currentLocation: nil,
            savedImageData: nil,
            candidateImageData: nil
        )
        #expect(result.result == .noMatch)
        #expect(result.wasGPS == false)
    }

    // MARK: - Vision evaluation

    @Test
    func visionNoMatchWhenOnlyOneSideHasData() {
        // Saved image present but no candidate — should degrade gracefully
        let fakeImageData = Data([0xFF, 0xD8, 0xFF, 0xD9])  // minimal JPEG header (not a real image)
        let result = PlaceMatchService.evaluate(
            savedLatitude: nil,
            savedLongitude: nil,
            savedGPSAccuracy: nil,
            currentLocation: nil,
            savedImageData: fakeImageData,
            candidateImageData: nil
        )
        #expect(result.result == .noMatch)
    }

    // MARK: - OR logic

    @Test
    func gpsMatchWinsEvenWithNilImages() {
        // GPS match + no vision → overall match via GPS
        let result = PlaceMatchService.evaluate(
            savedLatitude: 51.5074,
            savedLongitude: -0.1278,
            savedGPSAccuracy: 5.0,
            currentLocation: CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 51.5074 + 0.00009,
                    longitude: -0.1278
                ),
                altitude: 0,
                horizontalAccuracy: 5.0,
                verticalAccuracy: -1,
                timestamp: .now
            ),
            savedImageData: nil,
            candidateImageData: nil
        )
        #expect(result.result == .match)
        #expect(result.wasGPS == true)
    }
}
