//
//  CameraManager.swift
//  Mori.Recorder
//
//  Gerenciador da câmera com preview e captura funcional
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

enum CameraPosition {
    case front, back
}

enum VideoQuality {
    case hd720, hd1080, uhd4k
    
    var preset: AVCaptureSession.Preset {
        switch self {
        case .hd720: return .hd1280x720
        case .hd1080: return .hd1920x1080
        case .uhd4k: return .hd4K3840x2160
        }
    }
}

class CameraManager: NSObject, ObservableObject {
    @Published var cameraPosition: CameraPosition = .back
    @Published var videoQuality: VideoQuality = .hd1080
    @Published var hdrEnabled: Bool = true
    @Published var stabilizationEnabled: Bool = true
    let audioEnabled: Bool = true
    @Published var aspectRatio: CaptureAspect = .wide
    @Published var zoomOptions: [CGFloat] = [1, 2]
    @Published var exposureRange: ClosedRange<Float> = -2...2
    @Published var cameraError: String?
    private let sessionQueue = DispatchQueue(label: "MoriRecorder.camera")
    private var zoomMultiplier: CGFloat = 1
    private var recordingAspect: CGFloat = 9.0 / 16.0
    private var recordingID: UUID?
    @Published var isRecording: Bool = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isSessionReady: Bool = false
    
    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentCamera: AVCaptureDevice?
    private var audioInput: AVCaptureDeviceInput?
    private var recordingCompletion: ((URL?) -> Void)?
    
    // Camera Controls
    @Published var zoom: CGFloat = 1.0
    @Published var exposure: Float = 0.0
    @Published var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    
    override init() {
        super.init()
    }
    
    // MARK: - Setup
    func setupCamera() {
        guard !isRecording else { return }
        isSessionReady = false
        cameraError = nil
        print("🎬 Setting up camera...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop a previous session before creating a new one.
            self.captureSession?.stopRunning()

            self.captureSession = AVCaptureSession()
            if self.captureSession?.canSetSessionPreset(self.videoQuality.preset) == true {
                self.captureSession?.sessionPreset = self.videoQuality.preset
            }
            
            guard let camera = self.getCamera(for: self.cameraPosition) else {
                DispatchQueue.main.async { self.cameraError = "Câmera indisponível neste dispositivo." }
                print("❌ Error: Could not access camera")
                return
            }
            
            self.currentCamera = camera
            
            do {
                // Remove existing inputs
                if let inputs = self.captureSession?.inputs {
                    for input in inputs {
                        self.captureSession?.removeInput(input)
                    }
                }
                
                // Video input
                let videoInput = try AVCaptureDeviceInput(device: camera)
                
                guard self.captureSession?.canAddInput(videoInput) == true else {
                    throw VideoExporter.failure("Não foi possível conectar a câmera.")
                }
                if self.captureSession?.canAddInput(videoInput) == true {
                    self.captureSession?.addInput(videoInput)
                    print("✅ Video input added")
                }
                
                // Audio input (if enabled)
                if self.audioEnabled {
                    if let audioDevice = AVCaptureDevice.default(for: .audio) {
                        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                        if self.captureSession?.canAddInput(audioInput) == true {
                            self.captureSession?.addInput(audioInput)
                            self.audioInput = audioInput
                            print("✅ Audio input added")
                        }
                    }
                }
                
                // Remove existing outputs
                if let outputs = self.captureSession?.outputs {
                    for output in outputs {
                        self.captureSession?.removeOutput(output)
                    }
                }
                
                // Video output
                self.videoOutput = AVCaptureMovieFileOutput()
                
                // Set max recording duration (to prevent issues)
                self.videoOutput?.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)
                
                guard self.captureSession?.canAddOutput(self.videoOutput!) == true else {
                    throw VideoExporter.failure("Não foi possível configurar a gravação.")
                }
                if self.captureSession?.canAddOutput(self.videoOutput!) == true {
                    self.captureSession?.addOutput(self.videoOutput!)
                    print("✅ Video output added")
                    
                    // Configure video stabilization
                    if let connection = self.videoOutput?.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = self.stabilizationEnabled ? .auto : .off
                            print("✅ Video stabilization configured")
                        }
                    }
                }
                
                // Configure camera settings
                self.configureCameraSettings(camera)
                self.configureZoom(camera)
                
                // Create preview layer
                guard let session = self.captureSession else { return }
                DispatchQueue.main.async {
                    let preview = AVCaptureVideoPreviewLayer(session: session)
                    preview.videoGravity = .resizeAspectFill
                    self.previewLayer = preview
                    print("✅ Preview layer created")
                }
                
                // Start session
                self.captureSession?.startRunning()
                print("✅ Capture session started and running")
                
                // Mark session as ready
                DispatchQueue.main.async {
                    self.isSessionReady = session.isRunning
                    print("✅ Camera is READY to record")
                }
                
            } catch {
                DispatchQueue.main.async { self.cameraError = error.localizedDescription }
            }
        }
    }
    
    private func configureCameraSettings(_ camera: AVCaptureDevice) {
        do {
            try camera.lockForConfiguration()
            
            // HDR
            if camera.activeFormat.isVideoHDRSupported {
                camera.automaticallyAdjustsVideoHDREnabled = hdrEnabled
            }
            
            // Focus
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            
            // Exposure
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            
            // White Balance
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Low Light Boost
            if camera.isLowLightBoostSupported {
                camera.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            
            camera.unlockForConfiguration()
            print("✅ Camera settings configured")
        } catch {
            print("❌ Error configuring camera: \(error.localizedDescription)")
        }
    }
    
    private func getCamera(for position: CameraPosition) -> AVCaptureDevice? {
        let avPosition: AVCaptureDevice.Position = position == .back ? .back : .front

        let types: [AVCaptureDevice.DeviceType] = position == .back
            ? [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
            : [.builtInWideAngleCamera]
        for type in types {
            if let device = AVCaptureDevice.default(type, for: .video, position: avPosition) { return device }
        }
        return nil
    }

    private func configureZoom(_ camera: AVCaptureDevice) {
        // Virtual-camera zoom starts at its widest lens. Normalize UI values to the wide lens.
        let switches = camera.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat(truncating: $0) }
        let hasUltraWide = camera.constituentDevices.contains { $0.deviceType == .builtInUltraWideCamera }
        zoomMultiplier = hasUltraWide ? 1 / (switches.first ?? 2) : 1
        let lower = camera.minAvailableVideoZoomFactor * zoomMultiplier
        let upper = camera.maxAvailableVideoZoomFactor * zoomMultiplier
        var options = [lower, CGFloat(1), CGFloat(2), CGFloat(5), CGFloat(8)] + switches.map { $0 * zoomMultiplier }
        options = Array(Set(options.filter { $0 >= lower && $0 <= upper })).sorted()
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = min(camera.maxAvailableVideoZoomFactor, max(camera.minAvailableVideoZoomFactor, 1 / zoomMultiplier))
            camera.unlockForConfiguration()
            let actual = camera.videoZoomFactor * zoomMultiplier
            let limits = camera.minExposureTargetBias...camera.maxExposureTargetBias
            DispatchQueue.main.async {
                self.zoomOptions = options
                self.zoom = actual
                self.exposureRange = limits
                self.exposure = camera.exposureTargetBias
            }
        } catch {
            DispatchQueue.main.async { self.cameraError = error.localizedDescription }
        }
    }

    func setExposure(_ bias: Float) {
        sessionQueue.async {
            guard let camera = self.currentCamera else { return }
            do {
                try camera.lockForConfiguration()
                let value = min(camera.maxExposureTargetBias, max(camera.minExposureTargetBias, bias))
                camera.setExposureTargetBias(value, completionHandler: nil)
                camera.unlockForConfiguration()
                DispatchQueue.main.async { self.exposure = value }
            } catch {
                DispatchQueue.main.async { self.cameraError = error.localizedDescription }
            }
        }
    }

    // MARK: - Permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        print("🔐 Requesting permissions...")
        
        AVCaptureDevice.requestAccess(for: .video) { videoGranted in
            print(videoGranted ? "✅ Video permission granted" : "❌ Video permission denied")
            
            if self.audioEnabled {
                AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                    print(audioGranted ? "✅ Audio permission granted" : "❌ Audio permission denied")
                    DispatchQueue.main.async {
                        let granted = videoGranted && audioGranted
                        completion(granted)
                        if granted {
                            self.setupCamera()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(videoGranted)
                    if videoGranted {
                        self.setupCamera()
                    }
                }
            }
        }
    }
    
    // MARK: - Recording
    func startRecording(duration: Int, completion: @escaping (URL?) -> Void) {
        guard let videoOutput = videoOutput else {
            print("❌ Video output not configured")
            completion(nil)
            return
        }
        
        guard let session = captureSession, session.isRunning else {
            print("❌ Capture session not running")
            completion(nil)
            return
        }
        
        guard !videoOutput.isRecording else {
            print("⚠️ Already recording")
            completion(nil)
            return
        }
        
        guard isSessionReady, !isRecording else { completion(nil); return }
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation ?? .portrait
        let videoOrientation: AVCaptureVideoOrientation
        switch orientation {
        case .landscapeLeft: videoOrientation = .landscapeLeft
        case .landscapeRight: videoOrientation = .landscapeRight
        case .portraitUpsideDown: videoOrientation = .portraitUpsideDown
        default: videoOrientation = .portrait
        }
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = videoOrientation
        }
        recordingAspect = aspectRatio.ratio(portrait: !orientation.isLandscape)
        let identifier = UUID()
        recordingID = identifier
        isRecording = true
        // Store completion handler
        self.recordingCompletion = completion
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        print("🎬 Starting recording to: \(tempURL.lastPathComponent)")
        print("   Duration: \(duration) seconds")
        print("   Audio: \(audioEnabled ? "ON" : "OFF")")
        
        // Start recording on main thread
        DispatchQueue.main.async {
            videoOutput.startRecording(to: tempURL, recordingDelegate: self)
            self.isRecording = true
            
            // Stop recording after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
                guard self.recordingID == identifier, videoOutput.isRecording else { return }
                print("⏹️ Stopping recording (duration reached)")
                videoOutput.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        guard let videoOutput = videoOutput, videoOutput.isRecording else {
            print("⚠️ Not recording")
            return
        }
        
        print("⏹️ Manually stopping recording")
        videoOutput.stopRecording()
    }
    
    // MARK: - Camera Controls
    func setZoom(_ value: CGFloat) {
        sessionQueue.async {
            guard let camera = self.currentCamera else { return }
            do {
                try camera.lockForConfiguration()
                camera.videoZoomFactor = max(camera.minAvailableVideoZoomFactor,
                    min(value / self.zoomMultiplier, camera.maxAvailableVideoZoomFactor))
                let actual = camera.videoZoomFactor * self.zoomMultiplier
                camera.unlockForConfiguration()
                DispatchQueue.main.async { self.zoom = actual }
            } catch {
                DispatchQueue.main.async { self.cameraError = error.localizedDescription }
            }
        }
    }

    func switchCamera() {
        guard !isRecording, isSessionReady else { return }
        cameraPosition = cameraPosition == .back ? .front : .back
        setupCamera()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("✅ Recording STARTED successfully")
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let successful = error == nil || ((error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool == true)
        let aspect = recordingAspect
        Task {
            var result: URL?
            var failure: String?
            if successful {
                do {
                    result = try await VideoExporter.export(urls: [outputFileURL], aspect: aspect)
                    try? FileManager.default.removeItem(at: outputFileURL)
                } catch {
                    failure = "Não foi possível aplicar a proporção: \(error.localizedDescription). O original foi preservado no app."
                    // Never discard a successful capture because postprocessing failed.
                    result = outputFileURL
                }
            } else {
                failure = error?.localizedDescription ?? "A gravação falhou."
                try? FileManager.default.removeItem(at: outputFileURL)
            }
            await MainActor.run {
                self.isRecording = false
                self.recordingID = nil
                self.cameraError = failure
                let completion = self.recordingCompletion
                self.recordingCompletion = nil
                completion?(result)
            }
        }
    }

    private func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: size)
            }
        } catch {
            return "unknown"
        }
        return "unknown"
    }
}
