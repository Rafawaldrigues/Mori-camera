//
//  CameraView.swift
//  Mori.Recorder
//
//  ✅ PREVIEW CORRIGIDO DE VERDADE AGORA
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var schedulerService: SchedulerService
    @State private var showingAlert = false
    @State private var cameraInitialized = false
    
    var body: some View {
        ZStack {
            // Camera Preview (fundo) - ✅ CORRIGIDO
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                CameraPreviewView(cameraManager: cameraManager)
                    .aspectRatio(cameraManager.aspectRatio.ratio(portrait: geometry.size.height >= geometry.size.width), contentMode: .fit)
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Overlay escuro semi-transparente
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // UI Controls (frente)
            GeometryReader { geometry in
              ScrollView {
               VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Mori.Recorder")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                    
                    // Camera status indicator
                    if cameraManager.isSessionReady {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.mint)
                            .font(.system(size: 14))
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Spacer()
                    
                    // Switch Camera Button
                    Button(action: {
                        cameraManager.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .disabled(schedulerService.isActive || !cameraManager.isSessionReady)
                .padding(.horizontal)
                .padding(.top, 10)
                CameraControlsPanel()
                    .padding(.horizontal)
                
                Spacer()
                
                // Status Card
                StatusCard(isDark: true)
                    .padding(.horizontal)
                
                Spacer()
                
                // Main Control Buttons
                HStack(spacing: 20) {
                    // Pause/Resume Button
                    if schedulerService.isActive {
                        Button(action: {
                            schedulerService.togglePause()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: schedulerService.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Theme.babyBlue)
                                    .shadow(color: .black.opacity(0.3), radius: 5)
                                
                                Text(schedulerService.isPaused ? "Retomar" : "Pausar")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 3)
                            }
                        }
                    }
                    
                    // Main Record Button
                    RecordButton(isRecording: schedulerService.isActive)
                        .onTapGesture {
                            toggleRecording()
                        }
                        .opacity(cameraManager.isSessionReady ? 1.0 : 0.5)
                    
                    // Stop Button
                    if schedulerService.isActive {
                        Button(action: {
                            schedulerService.stopScheduler()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Theme.rose)
                                    .shadow(color: .black.opacity(0.3), radius: 5)
                                
                                Text("Parar")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 3)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
                
                // Quick Settings
                QuickSettingsPanel(isDark: true)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
               }
               .frame(minHeight: geometry.size.height)
              }
            }
        }
        .onAppear {
            print("👁️ CameraView appeared")
            if !cameraInitialized {
                print("📷 Initializing camera...")
                cameraManager.requestPermissions { granted in
                    print(granted ? "✅ Permissions granted, camera will initialize" : "❌ Permissions denied")
                    cameraInitialized = granted
                    showingAlert = !granted
                }
            }
        }
        .alert("Câmera", isPresented: Binding(
            get: { cameraManager.cameraError != nil },
            set: { if !$0 { cameraManager.cameraError = nil } }
        )) {
            Button("OK", role: .cancel) { cameraManager.cameraError = nil }
        } message: {
            Text(cameraManager.cameraError ?? "Não foi possível acessar a câmera.")
        }
        .alert("Permissões Necessárias", isPresented: $showingAlert) {
            Button("Configurações", action: openSettings)
            Button("OK", role: .cancel) { }
        } message: {
            Text("Por favor, permita acesso à câmera, microfone e notificações nas configurações do iPhone.")
        }
    }
    
    private func toggleRecording() {
        // Block if camera not ready
        guard cameraManager.isSessionReady else {
            print("⚠️ Cannot start - camera not ready yet")
            return
        }
        
        if schedulerService.isActive {
            schedulerService.stopScheduler()
        } else {
            guard !cameraManager.isRecording else { return }
            schedulerService.startScheduler()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Camera Preview View (✅ TOTALMENTE REESCRITO)
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        print("📱 PreviewView created")
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // ✅ ATUALIZAR preview layer sempre que mudar
        if let previewLayer = cameraManager.previewLayer {
            if uiView.layer.sublayers?.contains(where: { $0 === previewLayer }) != true {
                // Remover layers antigas
                uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                
                // Adicionar nova preview layer
                previewLayer.frame = uiView.bounds
                previewLayer.videoGravity = .resizeAspectFill
                uiView.layer.addSublayer(previewLayer)
                
                print("✅ Preview layer added to view")
            } else {
                // Atualizar frame se já existe
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// ✅ View customizada para preview
class PreviewView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Atualizar frame de todas as sublayers quando view mudar de tamanho
        layer.sublayers?.forEach { sublayer in
            if sublayer is AVCaptureVideoPreviewLayer {
                sublayer.frame = bounds
                if let preview = sublayer as? AVCaptureVideoPreviewLayer,
                   let connection = preview.connection, connection.isVideoOrientationSupported {
                    switch window?.windowScene?.interfaceOrientation {
                    case .landscapeLeft: connection.videoOrientation = .landscapeLeft
                    case .landscapeRight: connection.videoOrientation = .landscapeRight
                    case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
                    default: connection.videoOrientation = .portrait
                    }
                }
            }
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    @EnvironmentObject var schedulerService: SchedulerService
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(schedulerService.isActive ? (schedulerService.isPaused ? Color.orange : Theme.mint) : Color.gray)
                    .frame(width: 12, height: 12)
                
                Text(schedulerService.isActive ? (schedulerService.isPaused ? "Pausado" : "Gravação Ativa") : "Inativo")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            
            if schedulerService.isActive && !schedulerService.isPaused {
                VStack(spacing: 6) {
                    Text("Próximo clipe em:")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(schedulerService.nextCaptureTime, style: .timer)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.lavender)
                }
            }
            
            Text("Quantidade de clipes: \(schedulerService.sessionClipsCount)/\(schedulerService.targetClipCount)")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Record Button
struct RecordButton: View {
    let isRecording: Bool
    @State private var isPressed = false
    @State private var pulse: Bool = false
    
    var body: some View {
        ZStack {
            // Pulse effect when recording
            if isRecording {
                Circle()
                    .fill(Theme.rose.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0 : 1)
                    .animation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                    .onAppear {
                        pulse = true
                    }
            }
            
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.lavender, Theme.rose]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Theme.lavender.opacity(0.6), radius: 20, x: 0, y: 10)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
            Image(systemName: isRecording ? "checkmark" : "play.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Quick Settings Panel
struct QuickSettingsPanel: View {
    @EnvironmentObject var schedulerService: SchedulerService
    @EnvironmentObject var cameraManager: CameraManager
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Stepper("Quantidade de clipes: \(schedulerService.targetClipCount)", value: $schedulerService.targetClipCount, in: 1...100)
                .disabled(schedulerService.isActive)
                .padding(10)
                .background(Color.black.opacity(0.6).cornerRadius(12))
            HStack(spacing: 12) {
                // Intervalo
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Theme.mint)
                        .font(.system(size: 16))
                    
                    Picker("", selection: $schedulerService.captureInterval) {
                        Text("1'").tag(1)
                        Text("3'").tag(3)
                        Text("5'").tag(5)
                        Text("10'").tag(10)
                        Text("15'").tag(15)
                        Text("30'").tag(30)
                        Text("1h").tag(60)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(Theme.lavender)
                    .disabled(schedulerService.isActive)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
                
                // Duração
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(Theme.peach)
                        .font(.system(size: 16))
                    
                    Picker("", selection: $schedulerService.clipDuration) {
                        Text("3s").tag(3)
                        Text("5s").tag(5)
                        Text("10s").tag(10)
                        Text("15s").tag(15)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(Theme.lavender)
                    .disabled(schedulerService.isActive)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
                

            }
        }
        .font(.system(size: 14, weight: .medium, design: .rounded))
        .foregroundColor(.white)
    }
}
