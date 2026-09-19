import SwiftUI
import SwiftData
import AVFoundation
import CoreLocation

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(sort: \VisitEntity.capturedAt, order: .reverse) private var existingVisits: [VisitEntity]
    
    @State private var cameraService = CameraService.shared
    @State private var isCapturing: Bool = false
    @State private var flashOn: Bool = false
    @State private var capturedImagePreview: UIImage? = nil
    @State private var showConfirmation: Bool = false
    @State private var antiCheatAlert: String? = nil
    @State private var verificationStepText: String = "Securing Telemetry..."
    @State private var priorState: TravelDetectionState = .potentialVisit
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Viewfinder layer
                if cameraService.isCameraAvailable && cameraService.isSessionRunning {
                    CameraPreviewRepresentable(session: cameraService.session)
                        .ignoresSafeArea()
                } else {
                    simulatorViewfinder
                }
                
                // Camera Overlays & Controls
                VStack {
                    // Top Telemetry Header
                    topTelemetryBar
                    
                    Spacer()
                    
                    // Reticle
                    reticleView
                    
                    Spacer()
                    
                    // Bottom Shutter & Controls
                    bottomControlsBar
                }
                .padding(.bottom, 20)
                
                if isCapturing {
                    Color.black.opacity(0.65).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.4)
                        
                        Text(verificationStepText)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Cross-referencing sensor bindings & perceptual dHash")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                priorState = appState.currentState
                cameraService.setupSession()
                appState.transitionTo(state: .photoCapture)
            }
            .onDisappear {
                cameraService.stopSession()
                if appState.currentState == .photoCapture {
                    appState.transitionTo(state: priorState)
                }
            }
            .alert("Anti-Cheat Verification Failed", isPresented: Binding(
                get: { antiCheatAlert != nil },
                set: { if !$0 { antiCheatAlert = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(antiCheatAlert ?? "")
            }
            .sheet(isPresented: $showConfirmation) {
                VisitConfirmationSheet(
                    capturedImage: capturedImagePreview,
                    onVisitSaved: {
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var simulatorViewfinder: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundColor(.white.opacity(0.6))
            
            Text("In-App Proof Camera")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("AVCaptureSession hardware pipeline ready.\nTap shutter to simulate live geo-tagged shutter release.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 32)
        }
    }
    
    private var topTelemetryBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("LIVE SENSOR BINDING")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
            
            Spacer()
            
            Button(action: { flashOn.toggle() }) {
                Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Button(action: { cameraService.switchCamera() }) {
                Image(systemName: "camera.rotate.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
    
    private var reticleView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                .frame(width: 260, height: 260)
            
            VStack(spacing: 4) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(appState.candidatePlaceName ?? "Aim at destination")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
    }
    
    private var bottomControlsBar: some View {
        VStack(spacing: 16) {
            // Location Badge
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption2)
                Text(String(format: "%.4f, %.4f", appState.candidateLatitude, appState.candidateLongitude))
                    .font(.caption2.monospaced())
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
            
            // Shutter Button
            Button(action: takePhoto) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 76, height: 76)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 62, height: 62)
                }
            }
            .disabled(isCapturing)
        }
    }
    
    // MARK: - Shutter Action
    
    private func takePhoto() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isCapturing = true
        verificationStepText = "Capturing Sensor-Bound Frame..."
        
        Task {
            do {
                let result = try await cameraService.capturePhoto()
                
                await MainActor.run {
                    self.verificationStepText = "Executing Anti-Cheat Audit..."
                    self.appState.transitionTo(state: .validating)
                }
                
                let existingHashes = existingVisits.map { $0.photoHash }.filter { !$0.isEmpty }
                let lastVisit = existingVisits.first
                
                let validation = AntiCheatEngine.shared.validateVisit(
                    currentLocation: result.location,
                    lastVisitLocation: lastVisit.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) },
                    lastVisitTime: lastVisit?.capturedAt,
                    currentPhotoHash: result.dHash,
                    existingHashes: existingHashes,
                    capturedTimestamp: result.timestamp,
                    travelMode: appState.pendingTravelMode
                )
                
                await MainActor.run {
                    self.isCapturing = false
                    
                    if !validation.isPassed {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.antiCheatAlert = validation.failureReason ?? "Anti-cheat validation failed."
                        self.appState.transitionTo(state: .awaitingConfirmation)
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        self.appState.pendingAntiCheatResult = validation
                        self.capturedImagePreview = result.image
                        self.appState.pendingCapturedImage = result.image
                        self.showConfirmation = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isCapturing = false
                    self.antiCheatAlert = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - UIViewRepresentable for AVCaptureVideoPreviewLayer

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
