//
//  TimeClipApp.swift
//  Mori.Recorder
//
//  App principal com inicialização correta dos managers
//

import SwiftUI

@main
struct TimeClipApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var schedulerService = SchedulerService()
    @StateObject private var storageManager = StorageManager()
    
    init() {
        print("🚀 App Initializing...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(cameraManager)
                .environmentObject(schedulerService)
                .environmentObject(storageManager)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .onAppear {
                    print("📱 App Appeared - Configuring managers...")
                    // Configurar conexão entre managers
                    schedulerService.configure(cameraManager: cameraManager, storageManager: storageManager)
                    print("✅ Managers configured")
                    
                    // CameraView solicita permissões e inicializa a câmera
                    // depois que o sistema autorizar o acesso.
                }
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var selectedTab: Tab = .camera
    
    enum Tab {
        case camera
        case gallery
        case compile
        case settings
    }
}
