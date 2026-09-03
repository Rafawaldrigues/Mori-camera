//
//  GalleryView.swift
//  Mori.Recorder
//
//  ✅ CORRIGIDO: Deletar individual, upload separado/compilado claro
//

import SwiftUI
import AVKit

struct GalleryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var storageManager: StorageManager
    @State private var selectedClip: VideoClip?
    @State private var selectedClips: Set<UUID> = []
    @State private var isSelectionMode: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var clipToDelete: VideoClip?
    @State private var isProcessing: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var successMessage: String = ""
    
    var groupedClips: [(String, [VideoClip])] {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [String: [VideoClip]] = [
            "Hoje": [],
            "Ontem": [],
            "Última Semana": [],
            "Mais Antigos": []
        ]
        
        for clip in storageManager.clips {
            if calendar.isDateInToday(clip.captureDate) {
                groups["Hoje"]?.append(clip)
            } else if calendar.isDateInYesterday(clip.captureDate) {
                groups["Ontem"]?.append(clip)
            } else if let daysAgo = calendar.dateComponents([.day], from: clip.captureDate, to: now).day, daysAgo <= 7 {
                groups["Última Semana"]?.append(clip)
            } else {
                groups["Mais Antigos"]?.append(clip)
            }
        }
        
        return [
            ("Hoje", groups["Hoje"] ?? []),
            ("Ontem", groups["Ontem"] ?? []),
            ("Última Semana", groups["Última Semana"] ?? []),
            ("Mais Antigos", groups["Mais Antigos"] ?? [])
        ].filter { !$0.1.isEmpty }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(isDark: appState.isDarkMode)
                    .ignoresSafeArea()
                
                if storageManager.clips.isEmpty {
                    EmptyGalleryView(isDark: appState.isDarkMode)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(groupedClips, id: \.0) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Section Header
                                    Text(group.0)
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary(isDark: appState.isDarkMode))
                                        .padding(.horizontal)
                                    
                                    // Clips Grid
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(group.1) { clip in
                                            ClipThumbnail(
                                                clip: clip,
                                                isDark: appState.isDarkMode,
                                                isSelected: selectedClips.contains(clip.id),
                                                isSelectionMode: isSelectionMode
                                            )
                                            .onTapGesture {
                                                if isSelectionMode {
                                                    toggleSelection(clip.id)
                                                } else {
                                                    selectedClip = clip
                                                }
                                            }
                                            .onLongPressGesture {
                                                // ✅ Long press para deletar
                                                if !isSelectionMode {
                                                    clipToDelete = clip
                                                    showDeleteAlert = true
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                // ✅ Loading overlay
                if isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Processando...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }
            .navigationTitle("Galeria")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !storageManager.clips.isEmpty {
                        Button(isSelectionMode ? "Cancelar" : "Selecionar") {
                            withAnimation {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedClips.removeAll()
                                }
                            }
                        }
                        .foregroundColor(Theme.lavender)
                    }
                }
            }
            .sheet(item: $selectedClip) { clip in
                VideoPlayerView(clip: clip, onDelete: {
                    clipToDelete = clip
                    showDeleteAlert = true
                })
            }
            .overlay(alignment: .bottom) {
                if isSelectionMode && !selectedClips.isEmpty {
                    UploadBar(
                        selectedCount: selectedClips.count,
                        isDark: appState.isDarkMode,
                        onCompiled: uploadCompiled,
                        onSeparate: uploadSeparate,
                        onDelete: deleteSelected
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .alert("Deletar Vídeo?", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Deletar", role: .destructive) {
                    if let clip = clipToDelete {
                        storageManager.deleteClip(clip)
                        clipToDelete = nil
                    }
                }
            } message: {
                Text("Este vídeo será deletado permanentemente do app.")
            }
            .alert("Sucesso!", isPresented: $showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text(successMessage)
            }
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedClips.contains(id) {
            selectedClips.remove(id)
        } else {
            selectedClips.insert(id)
        }
    }
    
    // ✅ CORRIGIDO: Upload separado funciona
    private func uploadSeparate() {
        let clips = storageManager.clips.filter { selectedClips.contains($0.id) }
        
        isProcessing = true
        print("📤 Uploading \(clips.count) clips separately...")
        
        storageManager.uploadClipsSeparately(clips) { success in
            DispatchQueue.main.async {
                isProcessing = false
                
                if success {
                    successMessage = "\(clips.count) vídeo(s) salvos na galeria do iPhone! 🎉"
                    showSuccessAlert = true
                    
                    // Reset selection
                    isSelectionMode = false
                    selectedClips.removeAll()
                }
            }
        }
    }
    
    // ✅ CORRIGIDO: Upload compilado funciona
    private func uploadCompiled() {
        let clips = storageManager.clips.filter { selectedClips.contains($0.id) }
        
        isProcessing = true
        print("🎬 Compiling \(clips.count) clips...")
        
        storageManager.compileClips(selectedClips: clips) { success, url in
            DispatchQueue.main.async {
                isProcessing = false
                
                if success {
                    successMessage = "Vídeo compilado salvo na galeria! 🎉"
                    showSuccessAlert = true
                    
                    // Reset selection
                    isSelectionMode = false
                    selectedClips.removeAll()
                }
            }
        }
    }
    
    // ✅ NOVO: Deletar selecionados
    private func deleteSelected() {
        let clips = storageManager.clips.filter { selectedClips.contains($0.id) }
        
        storageManager.deleteClips(clips)
        
        // Reset selection
        isSelectionMode = false
        selectedClips.removeAll()
    }
}

// MARK: - Empty Gallery View
struct EmptyGalleryView: View {
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(Theme.lavender.opacity(0.5))
            
            Text("Nenhum clipe ainda")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textPrimary(isDark: isDark))
            
            Text("Inicie a gravação para capturar seus primeiros momentos")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(Theme.textSecondary(isDark: isDark))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Clip Thumbnail
struct ClipThumbnail: View {
    let clip: VideoClip
    let isDark: Bool
    let isSelected: Bool
    let isSelectionMode: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                // Thumbnail
                if let thumbnail = clip.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Theme.cardBackground(isDark: isDark))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "video.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Theme.lavender.opacity(0.3))
                        )
                }
                
                // Play button overlay
                if !isSelectionMode {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Duration label
                Text(clip.formattedTime)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(6)
            }
            
            // Selection indicator
            if isSelectionMode {
                Circle()
                    .fill(isSelected ? Theme.mint : Color.gray.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: isSelected ? "checkmark" : "")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .padding(8)
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.mint : Color.clear, lineWidth: 3)
        )
    }
}

// MARK: - Upload Bar (✅ CORRIGIDO: Botões mais claros)
struct UploadBar: View {
    let selectedCount: Int
    let isDark: Bool
    let onCompiled: () -> Void
    let onSeparate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                Text("\(selectedCount) vídeo(s) selecionado(s)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textPrimary(isDark: isDark))
                
                HStack(spacing: 12) {
                    // ✅ Botão SEPARADOS - salva cada vídeo individual na galeria
                    Button(action: onSeparate) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 20))
                            Text("Salvar\nSeparados")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.peach)
                        .cornerRadius(12)
                    }
                    
                    // ✅ Botão COMPILADO - junta tudo em 1 vídeo e salva na galeria
                    Button(action: onCompiled) {
                        VStack(spacing: 4) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 20))
                            Text("Compilar e\nSalvar")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.lavender)
                        .cornerRadius(12)
                    }
                    
                    // ✅ Botão DELETAR
                    Button(action: onDelete) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                            Text("Deletar")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.rose)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Theme.cardBackground(isDark: isDark))
        }
    }
}

// MARK: - Video Player View (✅ Adicionado botão delete)
struct VideoPlayerView: View {
    let clip: VideoClip
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VideoPlayer(player: AVPlayer(url: clip.url))
                .ignoresSafeArea()
                .navigationTitle(clip.formattedDate)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fechar") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
