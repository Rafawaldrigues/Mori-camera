//
//  CompileView.swift
//  Mori.Recorder
//
//  ✅ CORRIGIDO: Compilação funciona de verdade agora
//

import SwiftUI

struct CompileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var storageManager: StorageManager
    @State private var isCompiling = false
    @State private var compilationProgress: Double = 0
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var compiledVideoURL: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(isDark: appState.isDarkMode)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Info Card
                        InfoCard(isDark: appState.isDarkMode)
                        
                        // Compile Button
                        Button(action: compileVideos) {
                            HStack {
                                if isCompiling {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "film.stack.fill")
                                        .font(.system(size: 20))
                                }
                                
                                Text(isCompiling ? "Compilando..." : "Compilar Todos os Vídeos")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Theme.lavender, Theme.babyBlue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Theme.lavender.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isCompiling || storageManager.clips.isEmpty)
                        .opacity(storageManager.clips.isEmpty ? 0.5 : 1)
                        
                        // Progress Bar
                        if isCompiling {
                            VStack(spacing: 8) {
                                ProgressView(value: compilationProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.mint))
                                    .scaleEffect(y: 2)
                                
                                Text("\(Int(compilationProgress * 100))%")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(Theme.textSecondary(isDark: appState.isDarkMode))
                            }
                            .padding(.top)
                        }
                        
                        // Instructions
                        InstructionsCard(isDark: appState.isDarkMode)
                    }
                    .padding()
                }
            }
            .navigationTitle("Compilar")
            .navigationBarTitleDisplayMode(.large)
            .alert("Vídeo Compilado!", isPresented: $showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Seu vídeo foi compilado com sucesso e salvo na galeria do iPhone! 🎉")
            }
            .alert("Erro na Compilação", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text("Não foi possível compilar os vídeos. Tente novamente.")
            }
        }
    }
    
    // ✅ CORRIGIDO: Agora compila de verdade
    private func compileVideos() {
        guard !storageManager.clips.isEmpty else { return }
        
        isCompiling = true
        compilationProgress = 0
        
        print("🎬 Starting real compilation...")
        
        // Simulate progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.compilationProgress < 0.9 {
                self.compilationProgress += 0.02
            }
        }
        
        // ✅ REAL COMPILATION
        storageManager.compileClips(selectedClips: storageManager.clips) { success, url in
            timer.invalidate()
            
            DispatchQueue.main.async {
                self.compilationProgress = 1.0
                self.isCompiling = false
                
                if success {
                    self.compiledVideoURL = url
                    self.showSuccessAlert = true
                    print("✅ Compilation SUCCESS!")
                } else {
                    self.showErrorAlert = true
                    print("❌ Compilation FAILED!")
                }
            }
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    @EnvironmentObject var storageManager: StorageManager
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(storageManager.clips.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.lavender)
                    
                    Text("Clipes disponíveis")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Theme.textSecondary(isDark: isDark))
                }
                
                Spacer()
                
                Image(systemName: "film.stack")
                    .font(.system(size: 50))
                    .foregroundColor(Theme.mint.opacity(0.3))
            }
            
            if !storageManager.clips.isEmpty {
                Divider()
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Theme.peach)
                    Text("Duração total:")
                        .foregroundColor(Theme.textSecondary(isDark: isDark))
                    Spacer()
                    Text(storageManager.totalDuration)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary(isDark: isDark))
                }
                .font(.system(size: 15, design: .rounded))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground(isDark: isDark))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// ✅ NOVO: Card de instruções
struct InstructionsCard: View {
    let isDark: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Como Usar")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary(isDark: isDark))
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(
                    icon: "film.stack",
                    text: "Use este botão para compilar TODOS os vídeos em um só",
                    isDark: isDark
                )
                
                InstructionRow(
                    icon: "square.grid.3x3",
                    text: "Na Galeria, selecione vídeos específicos para fazer upload",
                    isDark: isDark
                )
                
                InstructionRow(
                    icon: "square.stack.3d.up",
                    text: "Botão 'Separados': envia cada vídeo individualmente",
                    isDark: isDark
                )
                
                InstructionRow(
                    icon: "film.stack",
                    text: "Botão 'Compilado': junta os selecionados em um vídeo",
                    isDark: isDark
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground(isDark: isDark))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    let isDark: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.lavender)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Theme.textSecondary(isDark: isDark))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
