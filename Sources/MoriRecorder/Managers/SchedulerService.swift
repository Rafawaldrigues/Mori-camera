//
//  SchedulerService.swift
//  Mori.Recorder
//
//  Serviço de agendamento com logs detalhados
//

import Foundation
import UserNotifications
import Combine

class SchedulerService: ObservableObject {
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var captureInterval: Int = 3
    @Published var clipDuration: Int = 5
    @Published var sessionClipsCount: Int = 0
    @Published var nextCaptureTime: Date = Date()
    
    @Published var useActiveHours: Bool = false
    @Published var startTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    @Published var endTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!
    
    private var timer: Timer?
    private var cameraManager: CameraManager?
    private var storageManager: StorageManager?
    private var isCapturing: Bool = false
    
    func configure(cameraManager: CameraManager, storageManager: StorageManager) {
        self.cameraManager = cameraManager
        self.storageManager = storageManager
        print("✅ SchedulerService configured with managers")
    }
    
    func startScheduler() {
        guard !isActive else {
            print("⚠️ Scheduler already active")
            return
        }
        
        guard cameraManager != nil, storageManager != nil else {
            print("❌ Managers not configured!")
            return
        }
        
        isActive = true
        isPaused = false
        sessionClipsCount = 0
        
        print("✅ Scheduler started")
        print("   Interval: \(captureInterval) minutes")
        print("   Duration: \(clipDuration) seconds")
        
        requestNotificationPermissions()
        
        // Capturar IMEDIATAMENTE
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.captureVideo()
        }
        
        // Agendar próximas capturas
        scheduleNextCapture()
    }
    
    func stopScheduler() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        
        print("⏹️ Scheduler stopped")
        print("   Total clips this session: \(sessionClipsCount)")
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            timer?.invalidate()
            timer = nil
            print("⏸️ Scheduler paused")
        } else {
            scheduleNextCapture()
            print("▶️ Scheduler resumed")
        }
    }
    
    private func scheduleNextCapture() {
        timer?.invalidate()
        
        let intervalSeconds = TimeInterval(captureInterval * 60)
        nextCaptureTime = Date().addingTimeInterval(intervalSeconds)
        
        print("⏰ Next capture scheduled in \(captureInterval) minutes")
        
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            print("⏰ Timer fired!")
            self?.captureVideo()
        }
    }
    
    private func captureVideo() {
        guard !isPaused else {
            print("⏸️ Capture skipped - paused")
            return
        }
        
        guard !isCapturing else {
            print("⚠️ Already capturing, skipping")
            return
        }
        
        guard let cameraManager = cameraManager,
              let storageManager = storageManager else {
            print("❌ Managers not available!")
            return
        }
        
        // WAIT FOR CAMERA TO BE READY
        guard cameraManager.isSessionReady else {
            print("❌ Camera not ready yet, retrying in 2 seconds...")
            print("   Session exists: \(cameraManager.captureSession != nil)")
            print("   Session running: \(cameraManager.captureSession?.isRunning ?? false)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.captureVideo()
            }
            return
        }
        
        isCapturing = true
        
        print("━━━━━━━━━━━━━━━━━━━━━━")
        print("🎬 STARTING VIDEO CAPTURE")
        print("   Duration: \(clipDuration) seconds")
        print("   Session clips: \(sessionClipsCount)")
        print("━━━━━━━━━━━━━━━━━━━━━━")
        
        cameraManager.startRecording(duration: clipDuration) { [weak self] url in
            guard let self = self else { return }
            
            self.isCapturing = false
            
            guard let url = url else {
                print("❌ Recording failed - no URL returned")
                return
            }
            
            print("━━━━━━━━━━━━━━━━━━━━━━")
            print("✅ VIDEO CAPTURED!")
            print("   File: \(url.lastPathComponent)")
            print("━━━━━━━━━━━━━━━━━━━━━━")
            
            // Save to storage
            storageManager.saveClip(url: url)
            
            // Increment counter
            self.sessionClipsCount += 1
            
            print("📊 Session clips: \(self.sessionClipsCount)")
            
            // Send notification
            self.sendCaptureNotification()
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    private func sendCaptureNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Mori.Recorder"
        content.body = "Novo vídeo capturado! 🎥 (\(sessionClipsCount) na sessão)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
