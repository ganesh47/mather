import ARKit
import AVFoundation
import Foundation
import Observation
import RealityKit
import SwiftUI

@MainActor
@Observable
final class RoomQuestLiveScanner: NSObject, RoomQuestScanner {
    struct Session: Identifiable {
        let id = UUID()
        let expectedRole: RoomQuestStationRole
        let continuation: CheckedContinuation<RoomQuestMarkerScanResult, Error>
    }

    private(set) var activeSession: Session?

    func scanMarker(for role: RoomQuestStationRole) async throws -> RoomQuestMarkerScanResult {
        try await withCheckedThrowingContinuation { continuation in
            activeSession = Session(expectedRole: role, continuation: continuation)
        }
    }

    func resolveScan(payload: String) {
        guard let session = activeSession else { return }
        guard let detectedRole = Self.role(from: payload) else {
            session.continuation.resume(throwing: RoomQuestScannerError.unavailable)
            activeSession = nil
            return
        }
        guard detectedRole == session.expectedRole else {
            session.continuation.resume(throwing: RoomQuestScannerError.wrongMarker(expected: session.expectedRole, detected: detectedRole))
            activeSession = nil
            return
        }
        session.continuation.resume(returning: RoomQuestMarkerScanResult(role: detectedRole, markerPayload: payload, referenceImageJPEGData: nil, usedARCelebration: true))
        activeSession = nil
    }

    func cancelScan() {
        guard let session = activeSession else { return }
        session.continuation.resume(throwing: RoomQuestScannerError.cancelled)
        activeSession = nil
    }

    private static func role(from payload: String) -> RoomQuestStationRole? {
        switch payload.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "mather:roomquest:redRocket:v1":
            return .redRocket
        case "mather:roomquest:blueBubble:v1":
            return .blueBubble
        default:
            return nil
        }
    }
}

struct RoomQuestScannerSheet: View {
    @Bindable var scanner: RoomQuestLiveScanner

    var body: some View {
        NavigationStack {
            Group {
                if let session = scanner.activeSession {
                    RoomQuestCameraScannerView(expectedRole: session.expectedRole) { payload in
                        scanner.resolveScan(payload: payload)
                    } onCancel: {
                        scanner.cancelScan()
                    }
                } else {
                    ContentUnavailableView("Camera verify", systemImage: "camera.viewfinder", description: Text("Preparing scanner…"))
                }
            }
            .navigationTitle("Camera verify")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct RoomQuestCameraScannerView: UIViewControllerRepresentable {
    let expectedRole: RoomQuestStationRole
    let onPayload: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.expectedRole = expectedRole
        controller.onPayload = onPayload
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    var expectedRole: RoomQuestStationRole = .redRocket
    var onPayload: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasResolved = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCamera()
        addOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !session.isRunning { session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    private func configureCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            onCancel?()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            onCancel?()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
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
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .title2)
        label.text = "Scan the \(expectedRole.title) marker"

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Use fallback instead", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.tintColor = .white
        button.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
    }

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
            self.session.stopRunning()
            self.presentARCelebration(for: payload)
        }
    }
}

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
