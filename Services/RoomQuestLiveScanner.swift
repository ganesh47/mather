import ARKit
import AVFoundation
import Foundation
import Observation
import RealityKit
import SwiftUI

// MARK: - Verify feedback

/// Result of a place-comparison attempt in `.verify` mode.
/// Drives the feedback overlay inside the scanner sheet.
enum VerifyFeedback: Equatable {
    case evaluating                   // PlaceMatchService is running
    case match                        // confirmed — continuation already resolved
    case close(wasGPS: Bool)          // almost there
    case noMatch(wasGPS: Bool)        // wrong place
}

// MARK: - Live scanner

@MainActor
@Observable
final class RoomQuestLiveScanner: NSObject, RoomQuestScanner {
    struct Session: Identifiable {
        let id = UUID()
        let expectedRole: RoomQuestStationRole
        let mode: RoomQuestScanMode
        let savedReference: RoomQuestSavedReference?
        let continuation: CheckedContinuation<RoomQuestMarkerScanResult, Error>
    }

    private(set) var activeSession: Session?
    private(set) var verifyFeedback: VerifyFeedback? = nil
    private var verificationTask: Task<Void, Never>? = nil

    /// Called whenever the verify result changes to `.close` or `.noMatch` so the engine
    /// can fire speech. Set by `AppModel` at startup.
    var onVerifyFeedback: ((VerifyFeedback) -> Void)? = nil

    /// Threshold settings — injected from `AppModel` so parents can tune from Settings.
    /// Reads `featureFlags.placeMatchThresholds` at scan time (each photo tap).
    var featureFlags: FeatureFlagService? = nil

    /// Location service — owned here so GPS coordinates are captured at the exact photo moment.
    let locationService = LocationService()

    // MARK: - Protocol

    func scanMarker(
        for role: RoomQuestStationRole,
        mode: RoomQuestScanMode,
        savedReference: RoomQuestSavedReference?
    ) async throws -> RoomQuestMarkerScanResult {
        cancelActiveSession()
        verifyFeedback = nil
        locationService.requestWhenInUseIfNeeded()
        locationService.startUpdates()
        return try await withCheckedThrowingContinuation { continuation in
            activeSession = Session(
                expectedRole: role,
                mode: mode,
                savedReference: savedReference,
                continuation: continuation
            )
        }
    }

    // MARK: - Resolution paths

    /// Called from `ScannerViewController` when a photo is taken.
    /// • Setup mode: include GPS from `locationService`, resolve immediately.
    /// • Verify mode: run PlaceMatchService; resolve on `.match`, set `verifyFeedback` otherwise.
    func resolveWithPhoto(_ jpegData: Data) {
        guard let session = activeSession else { return }

        switch session.mode {

        case .setup:
            let loc = locationService.lastLocation
            session.continuation.resume(returning: RoomQuestMarkerScanResult(
                role: session.expectedRole,
                markerPayload: nil,
                referenceImageJPEGData: jpegData,
                referenceLatitude: loc?.coordinate.latitude,
                referenceLongitude: loc?.coordinate.longitude,
                referenceGPSAccuracy: loc?.horizontalAccuracy,
                usedARCelebration: false
            ))
            locationService.stopUpdates()
            activeSession = nil

        case .verify:
            verificationTask?.cancel()
            let savedRef = session.savedReference
            let currentLocation = locationService.lastLocation
            let expectedRole = session.expectedRole
            let continuation = session.continuation
            let sessionID = session.id
            let thresholds = featureFlags?.placeMatchThresholds ?? .default
            verifyFeedback = .evaluating

            verificationTask = Task.detached { [weak self, savedRef, currentLocation, thresholds] in
                let (result, wasGPS, gpsMetres, visionDist) = PlaceMatchService.evaluate(
                    savedLatitude: savedRef?.latitude,
                    savedLongitude: savedRef?.longitude,
                    savedGPSAccuracy: savedRef?.gpsAccuracy,
                    currentLocation: currentLocation,
                    savedImageData: savedRef?.imageJPEGData,
                    candidateImageData: jpegData,
                    thresholds: thresholds
                )
                // Log raw distances — useful for threshold tuning.
                let gpsStr   = gpsMetres.map   { String(format: "%.1f m", $0) } ?? "n/a"
                let visStr   = visionDist.map  { String(format: "%.3f",   $0) } ?? "n/a"
                print("[PlaceMatch] result=\(result) wasGPS=\(wasGPS) GPS=\(gpsStr) Vision=\(visStr)")
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self,
                          self.activeSession?.id == sessionID else {
                        // Session was cancelled or replaced while PlaceMatchService ran.
                        return
                    }
                    self.verificationTask = nil
                    switch result {
                    case .match:
                        self.verifyFeedback = .match
                        continuation.resume(returning: RoomQuestMarkerScanResult(
                            role: expectedRole,
                            markerPayload: nil,
                            referenceImageJPEGData: nil,
                            usedARCelebration: false
                        ))
                        self.locationService.stopUpdates()
                        self.activeSession = nil
                    case .close:
                        let feedback = VerifyFeedback.close(wasGPS: wasGPS)
                        self.verifyFeedback = feedback
                        self.onVerifyFeedback?(feedback)
                    case .noMatch:
                        let feedback = VerifyFeedback.noMatch(wasGPS: wasGPS)
                        self.verifyFeedback = feedback
                        self.onVerifyFeedback?(feedback)
                    }
                }
            }
        }
    }

    /// Called when the QR scanner detects a valid marker (setup mode only).
    func resolveScan(payload: String) {
        guard let session = activeSession else { return }
        guard let detectedRole = Self.role(from: payload) else {
            session.continuation.resume(throwing: RoomQuestScannerError.unavailable)
            locationService.stopUpdates()
            activeSession = nil
            return
        }
        guard detectedRole == session.expectedRole else {
            session.continuation.resume(throwing: RoomQuestScannerError.wrongMarker(expected: session.expectedRole, detected: detectedRole))
            locationService.stopUpdates()
            activeSession = nil
            return
        }
        session.continuation.resume(returning: RoomQuestMarkerScanResult(
            role: detectedRole,
            markerPayload: payload,
            referenceImageJPEGData: nil,
            usedARCelebration: true
        ))
        locationService.stopUpdates()
        activeSession = nil
    }

    func resolveWithConfirm() {
        guard let session = activeSession else { return }
        session.continuation.resume(returning: RoomQuestMarkerScanResult(
            role: session.expectedRole,
            markerPayload: nil,
            referenceImageJPEGData: nil,
            usedARCelebration: false
        ))
        locationService.stopUpdates()
        activeSession = nil
    }

    func cancelScan() {
        cancelActiveSession()
    }

    private func cancelActiveSession() {
        verificationTask?.cancel()
        verificationTask = nil
        guard let session = activeSession else {
            verifyFeedback = nil
            return
        }
        session.continuation.resume(throwing: RoomQuestScannerError.cancelled)
        locationService.stopUpdates()
        activeSession = nil
        verifyFeedback = nil
    }

    // MARK: - Helpers

    private static func role(from payload: String) -> RoomQuestStationRole? {
        switch payload.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "mather:roomquest:redRocket:v1":  return .redRocket
        case "mather:roomquest:blueBubble:v1": return .blueBubble
        default: return nil
        }
    }
}

// MARK: - Sheet wrapper

struct RoomQuestScannerSheet: View {
    @Bindable var scanner: RoomQuestLiveScanner

    var body: some View {
        NavigationStack {
            Group {
                if let session = scanner.activeSession {
                    RoomQuestCameraScannerView(
                        expectedRole: session.expectedRole,
                        scanMode: session.mode,
                        savedImageData: session.savedReference?.imageJPEGData,
                        verifyFeedback: scanner.verifyFeedback,
                        onPayload: { payload in scanner.resolveScan(payload: payload) },
                        onPhoto: { jpegData in scanner.resolveWithPhoto(jpegData) },
                        onConfirm: { scanner.resolveWithConfirm() },
                        onCancel: { scanner.cancelScan() }
                    )
                } else {
                    ContentUnavailableView("Camera verify", systemImage: "camera.viewfinder", description: Text("Preparing scanner…"))
                }
            }
            .navigationTitle("Camera verify")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - UIViewControllerRepresentable bridge

private struct RoomQuestCameraScannerView: UIViewControllerRepresentable {
    let expectedRole: RoomQuestStationRole
    let scanMode: RoomQuestScanMode
    let savedImageData: Data?
    let verifyFeedback: VerifyFeedback?
    let onPayload: (String) -> Void
    let onPhoto: (Data) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.expectedRole = expectedRole
        controller.scanMode = scanMode
        controller.savedImageData = savedImageData
        controller.onPayload = onPayload
        controller.onPhoto = onPhoto
        controller.onConfirm = onConfirm
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if let feedback = verifyFeedback {
            uiViewController.applyVerifyFeedback(feedback)
        }
    }
}

// MARK: - ScannerViewController

final class ScannerViewController: UIViewController,
    @preconcurrency AVCaptureMetadataOutputObjectsDelegate,
    AVCapturePhotoCaptureDelegate {

    var expectedRole: RoomQuestStationRole = .redRocket
    var scanMode: RoomQuestScanMode = .setup
    var savedImageData: Data? = nil
    var onPayload: ((String) -> Void)?
    var onPhoto: ((Data) -> Void)?
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var hasResolved = false
    private var isEvaluating = false     // verify mode: prevents re-tap while PlaceMatch runs

    // Verify mode overlays
    private var thumbnailContainer: UIView?
    private var feedbackBanner: UIView?
    private var feedbackLabel: UILabel?
    private var primaryButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCamera()
        addOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !captureSession.isRunning { captureSession.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning { captureSession.stopRunning() }
    }

    private func configureCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
        else {
            onCancel?()
            return
        }
        captureSession.addInput(input)

        // QR metadata only needed in setup mode (verify uses photo comparison)
        if scanMode == .setup {
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
        }

        let photoOut = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOut) {
            captureSession.addOutput(photoOut)
            self.photoOutput = photoOut
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func addOverlay() {
        switch scanMode {
        case .setup:
            addSetupOverlay()
        case .verify:
            addVerifyOverlay()
        }
    }

    // MARK: Setup overlay

    private func addSetupOverlay() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .title2)
        label.text = "Point at the \(expectedRole.title) spot, then save a photo"

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .large
        config.buttonSize = .large
        config.title = "📸 Save this place"
        config.baseBackgroundColor = .systemBlue

        let btn = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.capturePhoto()
        })
        btn.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = makeCancelButton()

        let stack = UIStackView(arrangedSubviews: [label, btn, cancelButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 88),
            btn.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    // MARK: Verify overlay

    private func addVerifyOverlay() {
        // --- Reference thumbnail (top-left) ---
        if let imageData = savedImageData, let uiImage = UIImage(data: imageData) {
            let container = makeThumbnailContainer(image: uiImage)
            view.addSubview(container)
            thumbnailContainer = container
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                container.widthAnchor.constraint(equalToConstant: 130),
            ])
        }

        // --- Primary action button ---
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .large
        config.buttonSize = .large
        config.title = "📸 Check my spot"
        config.baseBackgroundColor = .systemGreen

        let btn = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            guard let self, !self.hasResolved, !self.isEvaluating else { return }
            self.isEvaluating = true
            self.updatePrimaryButton(enabled: false)
            self.capturePhoto()
        })
        btn.translatesAutoresizingMaskIntoConstraints = false
        self.primaryButton = btn

        let cancelButton = makeCancelButton()

        // --- Feedback banner (hidden until feedback arrives) ---
        let bannerView = UIView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.layer.cornerRadius = 14
        bannerView.clipsToBounds = true
        bannerView.isHidden = true
        self.feedbackBanner = bannerView

        let bannerLabel = UILabel()
        bannerLabel.translatesAutoresizingMaskIntoConstraints = false
        bannerLabel.textAlignment = .center
        bannerLabel.numberOfLines = 0
        bannerLabel.textColor = .white
        bannerLabel.font = .preferredFont(forTextStyle: .headline)
        bannerView.addSubview(bannerLabel)
        self.feedbackLabel = bannerLabel

        NSLayoutConstraint.activate([
            bannerLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 16),
            bannerLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -16),
            bannerLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 12),
            bannerLabel.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: -12)
        ])

        let stack = UIStackView(arrangedSubviews: [bannerView, btn, cancelButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 88),
            btn.widthAnchor.constraint(equalTo: stack.widthAnchor),
            bannerView.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func makeThumbnailContainer(image: UIImage) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        container.layer.cornerRadius = 12
        container.clipsToBounds = true

        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10

        let caption = UILabel()
        caption.translatesAutoresizingMaskIntoConstraints = false
        caption.text = "Find this place"
        caption.textColor = .white
        caption.font = .preferredFont(forTextStyle: .caption1)
        caption.textAlignment = .center

        container.addSubview(imageView)
        container.addSubview(caption)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            imageView.heightAnchor.constraint(equalToConstant: 90),
            caption.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            caption.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            caption.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            caption.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    private func makeCancelButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Use fallback instead", for: .normal)
        btn.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        btn.tintColor = .white
        btn.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)
        return btn
    }

    // MARK: Verify feedback

    /// Called from `updateUIViewController` when `verifyFeedback` changes.
    func applyVerifyFeedback(_ feedback: VerifyFeedback) {
        switch feedback {
        case .evaluating:
            updatePrimaryButton(enabled: false)
            feedbackBanner?.isHidden = true

        case .match:
            // Sheet auto-dismisses when `activeSession` is set to nil in scanner.
            // Camera stops in `viewWillDisappear`. Nothing to do here.
            break

        case .close(let wasGPS):
            isEvaluating = false
            updatePrimaryButton(enabled: true)
            let msg = wasGPS
                ? "Almost there! Walk a bit closer, then tap again."
                : "Almost! Move the camera to look more like the saved photo."
            showFeedbackBanner(message: msg, color: UIColor.systemOrange)

        case .noMatch(let wasGPS):
            isEvaluating = false
            updatePrimaryButton(enabled: true)
            let msg = wasGPS
                ? "Wrong place — keep walking and looking around."
                : "Wrong place — the camera view looks different. Keep searching."
            showFeedbackBanner(message: msg, color: UIColor.systemRed.withAlphaComponent(0.85))
        }
    }

    private func showFeedbackBanner(message: String, color: UIColor) {
        feedbackLabel?.text = message
        feedbackBanner?.backgroundColor = color
        feedbackBanner?.isHidden = false
    }

    private func updatePrimaryButton(enabled: Bool) {
        primaryButton?.isEnabled = enabled
        primaryButton?.alpha = enabled ? 1.0 : 0.6
    }

    // MARK: Photo capture

    private func capturePhoto() {
        guard !hasResolved else { return }
        guard let photoOutput else {
            onCancel?()
            return
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let jpegData = photo.fileDataRepresentation() else {
            Task { @MainActor [weak self] in self?.onCancel?() }
            return
        }
        Task { @MainActor [weak self] in
            guard let self, !self.hasResolved else { return }
            if self.scanMode == .setup {
                // Setup: stop camera now, resolve immediately
                self.hasResolved = true
                self.captureSession.stopRunning()
                self.onPhoto?(jpegData)
            } else {
                // Verify: keep camera running for retries; scanner drives resolution
                self.onPhoto?(jpegData)
            }
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate (setup only)

    @MainActor
    private func presentARCelebration(for payload: String) {
        let celebration = RoomQuestARCelebrationViewController(role: expectedRole) { [weak self] in
            self?.onPayload?(payload)
        }
        celebration.modalPresentationStyle = .fullScreen
        present(celebration, animated: false)
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let payload = object.stringValue
        else { return }

        Task { @MainActor [weak self] in
            guard let self, !self.hasResolved else { return }
            self.hasResolved = true
            self.captureSession.stopRunning()
            self.presentARCelebration(for: payload)
        }
    }
}

// MARK: - AR Celebration

@MainActor
private final class RoomQuestARCelebrationViewController: UIViewController {
    private let role: RoomQuestStationRole
    private let onComplete: () -> Void
    private var arView: ARView?
    private var completed = false

    init(role: RoomQuestStationRole, onComplete: @escaping () -> Void) {
        self.role = role
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let arView = ARView(frame: view.bounds)
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        NSLayoutConstraint.activate([
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.arView = arView

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .title1)
        label.text = "\(role.title) found!"
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])

        runCelebration(on: arView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            self?.finishIfNeeded()
        }
    }

    private func runCelebration(on arView: ARView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        arView.session.run(configuration)

        let anchor = AnchorEntity(world: [0, 0, -0.8])
        let mesh = MeshResource.generateSphere(radius: 0.12)
        let color: UIColor = role == .redRocket ? .systemRed : .systemBlue
        let material = SimpleMaterial(color: color, roughness: 0.2, isMetallic: false)
        let orb = ModelEntity(mesh: mesh, materials: [material])
        orb.position = [0, 0, 0]

        let ringMesh = MeshResource.generateBox(size: 0.04)
        let ringMaterial = SimpleMaterial(color: color.withAlphaComponent(0.75), roughness: 0.1, isMetallic: true)
        for offset in [-0.22 as Float, 0.22] {
            let spark = ModelEntity(mesh: ringMesh, materials: [ringMaterial])
            spark.position = [offset, 0.08, 0]
            anchor.addChild(spark)
        }

        anchor.addChild(orb)
        arView.scene.addAnchor(anchor)

        orb.move(to: Transform(scale: SIMD3<Float>(repeating: 1.35), rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]), translation: [0, 0.05, 0]), relativeTo: orb, duration: 0.9, timingFunction: .easeInOut)
    }

    private func finishIfNeeded() {
        guard !completed else { return }
        completed = true
        arView?.session.pause()
        dismiss(animated: false) { [onComplete] in
            onComplete()
        }
    }
}
