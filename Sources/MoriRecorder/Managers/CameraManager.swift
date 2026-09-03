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
    @Published var audioEnabled: Bool = true
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
        print("🎬 Setting up camera...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Stop a previous session before creating a new one.
            self.captureSession?.stopRunning()

            self.captureSession = AVCaptureSession()
            self.captureSession?.sessionPreset = self.videoQuality.preset
            
            guard let camera = self.getCamera(for: self.cameraPosition) else {
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
                
                // Create preview layer
                DispatchQueue.main.async {
                    let preview = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                    preview.videoGravity = .resizeAspectFill
                    self.previewLayer = preview
                    print("✅ Preview layer created")
                }
                
                // Start session
                self.captureSession?.startRunning()
                print("✅ Capture session started and running")
                
                // Mark session as ready
                DispatchQueue.main.async {
                    self.isSessionReady = true
                    print("✅ Camera is READY to record")
                }
                
            } catch {
                print("❌ Error setting up camera: \(error.localizedDescription)")
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

        // Do not use DiscoverySession.devices.first here.
        // DiscoverySession does not guarantee the order of devices according
        // to the requested deviceTypes. On some iPhones this can select a
        // virtual camera (such as Dual Wide), where 1.0x may correspond to
        // the ultra-wide lens.
        //
        // Explicitly request the physical Wide Angle camera. On iPhone 15
        // this is the normal rear 1x camera.
        if let wideAngle = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: avPosition
        ) {
            print("📷 Selected camera: \(wideAngle.localizedName) [Wide Angle / 1x]")
            return wideAngle
        }

        // Fallback, still restricted to Wide Angle so a virtual multi-camera
        // device cannot accidentally be selected.
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: avPosition
        )

        let camera = discoverySession.devices.first
        if let camera {
            print("📷 Selected fallback camera: \(camera.localizedName) [Wide Angle]")
        }
        return camera
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) { [weak self] in
                guard let self = self, videoOutput.isRecording else { return }
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
    func setZoom(_ zoom: CGFloat) {
        guard let camera = currentCamera else { return }
        
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = max(1.0, min(zoom, camera.activeFormat.videoMaxZoomFactor))
            camera.unlockForConfiguration()
            
            self.zoom = camera.videoZoomFactor
        } catch {
            print("❌ Error setting zoom: \(error)")
        }
    }
    
    func switchCamera() {
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
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        if let error = error {
            print("❌ Recording error: \(error.localizedDescription)")
            recordingCompletion?(nil)
        } else {
            print("✅ Recording FINISHED successfully")
            print("   File: \(outputFileURL.lastPathComponent)")
            print("   Size: \(self.getFileSize(url: outputFileURL))")
            recordingCompletion?(outputFileURL)
        }
        
        recordingCompletion = nil
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
