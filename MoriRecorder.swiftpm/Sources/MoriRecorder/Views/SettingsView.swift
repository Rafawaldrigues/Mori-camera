//
//  SettingsView.swift
//  TimeClip
//
//  Configurações do aplicativo
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var schedulerService: SchedulerService
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(isDark: appState.isDarkMode)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance Section
                        SettingsSection(title: "Aparência", isDark: appState.isDarkMode) {
                            Toggle(isOn: $appState.isDarkMode) {
                                HStack {
                                    Image(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .foregroundColor(appState.isDarkMode ? Theme.lavender : Theme.peach)
                                    Text("Modo Escuro")
                                        .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                }
                            }
                            .tint(Theme.mint)
                        }
                        
                        // Camera Section
                        SettingsSection(title: "Câmera", isDark: appState.isDarkMode) {
                            // Camera Position
                            Picker("Posição da Câmera", selection: $cameraManager.cameraPosition) {
                                Label("Traseira", systemImage: "camera.fill").tag(CameraPosition.back)
                                Label("Frontal", systemImage: "camera.fill").tag(CameraPosition.front)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Divider()
                            
                            // Video Quality
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Qualidade do Vídeo")
                                    .foregroundColor(Theme.textSecondary(isDark: appState.isDarkMode))
                                    .font(.system(size: 13, design: .rounded))
                                
                                Picker("", selection: $cameraManager.videoQuality) {
                                    Text("720p").tag(VideoQuality.hd720)
                                    Text("1080p").tag(VideoQuality.hd1080)
                                    Text("4K").tag(VideoQuality.uhd4k)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            Divider()
                            
                            // HDR
                            Toggle(isOn: $cameraManager.hdrEnabled) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(Theme.babyBlue)
                                    Text("HDR")
                                        .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                }
                            }
                            .tint(Theme.mint)
                            
                            // Image Stabilization
                            Toggle(isOn: $cameraManager.stabilizationEnabled) {
                                HStack {
                                    Image(systemName: "gyroscope")
                                        .foregroundColor(Theme.rose)
                                    Text("Estabilização de Imagem")
                                        .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                }
                            }
                            .tint(Theme.mint)
                            
                        }
                        .disabled(schedulerService.isActive || !cameraManager.isSessionReady)
                        .onChange(of: cameraManager.cameraPosition) { _ in cameraManager.setupCamera() }
                        .onChange(of: cameraManager.videoQuality) { _ in cameraManager.setupCamera() }
                        .onChange(of: cameraManager.hdrEnabled) { _ in cameraManager.setupCamera() }
                        .onChange(of: cameraManager.stabilizationEnabled) { _ in cameraManager.setupCamera() }

                        // Schedule Section
                        SettingsSection(title: "Agendamento", isDark: appState.isDarkMode) {
                            // Active Hours
                            Toggle(isOn: $schedulerService.useActiveHours) {
                                HStack {
                                    Image(systemName: "clock.badge.checkmark")
                                        .foregroundColor(Theme.peach)
                                    Text("Horário Ativo")
                                        .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                }
                            }
                            .tint(Theme.mint)
                            
                            if schedulerService.useActiveHours {
                                Divider()
                                
                                HStack {
                                    Text("Início:")
                                        .foregroundColor(Theme.textSecondary(isDark: appState.isDarkMode))
                                    Spacer()
                                    DatePicker("", selection: $schedulerService.startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .accentColor(Theme.lavender)
                                }
                                
                                HStack {
                                    Text("Fim:")
                                        .foregroundColor(Theme.textSecondary(isDark: appState.isDarkMode))
                                    Spacer()
                                    DatePicker("", selection: $schedulerService.endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .accentColor(Theme.lavender)
                                }
                            }
                        }
                        
                        // Storage Section
                        SettingsSection(title: "Armazenamento", isDark: appState.isDarkMode) {
                            HStack {
                                Image(systemName: "internaldrive.fill")
                                    .foregroundColor(Theme.mint)
                                Text("Espaço usado")
                                    .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                Spacer()
                                Text("1.2 GB")
                                    .foregroundColor(Theme.textSecondary(isDark: appState.isDarkMode))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            
                            Divider()
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(Theme.rose)
                                    Text("Limpar Clipes Antigos")
                                        .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                    Spacer()
                                }
                            }
                        }
                        
                        // About Section
                        SettingsSection(title: "Sobre", isDark: appState.isDarkMode) {
                            HStack {
                                Text("Versão")
                                    .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(Theme.textSecondary(isDark: appState.isDarkMode))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let isDark: Bool
    let content: Content
    
    init(title: String, isDark: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isDark = isDark
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary(isDark: isDark))
            
            VStack(spacing: 12) {
                content
            }
            .font(.system(size: 15, design: .rounded))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground(isDark: isDark))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}
