import CoreLocation
import UIKit
import Vision

// MARK: - Result types

enum PlaceMatchResult: Equatable {
    case match      // confident — child is at the right place
    case close      // nearby but not quite — encourage small adjustment
    case noMatch    // clearly wrong location
}

// MARK: - Service

/// Pure namespace — stateless, no actor isolation.
/// Runs Vision feature-print comparison AND GPS distance check, then combines
/// them with OR logic so either strong signal alone is enough to confirm.
///
/// **Indoor play** → GPS unreliable; Vision drives the verdict.
/// **Outdoor play** → GPS reliable (±3–5 m); either signal can confirm.
enum PlaceMatchService {

    // MARK: - Tunable thresholds

    /// Child must be within this many metres of the saved GPS coordinate (outdoor).
    /// Kept tight (8 m) to avoid indoor false positives — two rooms in the same house
    /// are often within 15 m of each other.
    static let gpsMatchMetres: Double = 8.0
    /// GPS within this range shows "almost there" instead of "wrong place".
    static let gpsCloseMetres: Double = 20.0
    /// VNFeaturePrintObservation L2 distance treated as same place (indoor).
    /// 0.65 was too lenient — different rooms in the same house routinely scored under 0.65
    /// because VNFeaturePrintObservation is a semantic similarity metric, not a geometric one.
    /// 0.25 requires photos to look very similar (same content, comparable framing).
    static let visionMatchDistance: Float = 0.25
    /// VNFeaturePrintObservation distance treated as "almost" (indoor).
    static let visionCloseDistance: Float = 0.50
    /// Discard GPS fixes with horizontal accuracy worse than this (metres).
    /// Reduced from 20 m to 10 m — indoor fixes frequently report ~15 m accuracy
    /// while actually being unreliable room-to-room.
    static let gpsAccuracyCutoff: Double = 10.0

    // MARK: - Evaluation

    /// Evaluate whether `currentLocation` / `candidateImageData` match the saved reference.
    /// - Returns: `(result, wasGPS, gpsMetres, visionDist)` where:
    ///   - `wasGPS` is `true` when GPS was the decisive signal (tailor speech)
    ///   - `gpsMetres` is the raw GPS distance in metres (nil when GPS was skipped)
    ///   - `visionDist` is the raw VNFeaturePrintObservation distance (nil when Vision was skipped)
    static func evaluate(
        savedLatitude: Double?,
        savedLongitude: Double?,
        savedGPSAccuracy: Double?,
        currentLocation: CLLocation?,
        savedImageData: Data?,
        candidateImageData: Data?
    ) -> (result: PlaceMatchResult, wasGPS: Bool, gpsMetres: Double?, visionDist: Float?) {
        let savedLoc = makeSavedLocation(lat: savedLatitude, lon: savedLongitude, accuracy: savedGPSAccuracy)
        let (gpsResult, gpsMetres) = evaluateGPS(saved: savedLoc, current: currentLocation)
        let (visResult, visionDist) = evaluateVision(reference: savedImageData, candidate: candidateImageData)

        // OR logic: either strong signal alone confirms place
        switch (gpsResult, visResult) {
        case (.match, _):  return (.match,   true,  gpsMetres, visionDist)
        case (_, .match):  return (.match,   false, gpsMetres, visionDist)
        case (.close, _):  return (.close,   true,  gpsMetres, visionDist)
        case (_, .close):  return (.close,   false, gpsMetres, visionDist)
        default:           return (.noMatch, false, gpsMetres, visionDist)
        }
    }

    // MARK: - GPS sub-evaluation

    private static func makeSavedLocation(lat: Double?, lon: Double?, accuracy: Double?) -> CLLocation? {
        guard let lat, let lon, let accuracy, accuracy > 0 else { return nil }
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            timestamp: .distantPast
        )
    }

    private static func evaluateGPS(saved: CLLocation?, current: CLLocation?) -> (PlaceMatchResult, Double?) {
        guard let saved, let current,
              saved.horizontalAccuracy > 0,   saved.horizontalAccuracy  <= gpsAccuracyCutoff,
              current.horizontalAccuracy > 0, current.horizontalAccuracy <= gpsAccuracyCutoff
        else { return (.noMatch, nil) }   // GPS unreliable — skip this signal

        let dist = current.distance(from: saved)
        if dist <= gpsMatchMetres { return (.match, dist) }
        if dist <= gpsCloseMetres { return (.close, dist) }
        return (.noMatch, dist)
    }

    // MARK: - Vision sub-evaluation

    private static func evaluateVision(reference: Data?, candidate: Data?) -> (PlaceMatchResult, Float?) {
        guard let refData = reference, let candData = candidate else { return (.noMatch, nil) }
        do {
            let refPrint  = try featurePrint(for: refData)
            let candPrint = try featurePrint(for: candData)
            var dist: Float = 0
            try refPrint.computeDistance(&dist, to: candPrint)
            if dist <= visionMatchDistance { return (.match, dist) }
            if dist <= visionCloseDistance { return (.close, dist) }
            return (.noMatch, dist)
        } catch {
            // Blurry / too-dark photo — treat as noMatch; grown-up fallback handles it
            return (.noMatch, nil)
        }
    }

    private static func featurePrint(for imageData: Data) throws -> VNFeaturePrintObservation {
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            throw PlaceMatchError.badImage
        }
        let request = VNGenerateImageFeaturePrintRequest()
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        guard let result = request.results?.first as? VNFeaturePrintObservation else {
            throw PlaceMatchError.noResult
        }
        return result
    }
}

enum PlaceMatchError: Error { case badImage, noResult }
