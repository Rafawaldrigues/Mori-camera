//
//  StorageManager.swift
//  Mori.Recorder
//
//  ✅ CORRIGIDO: Salvar na galeria, deletar individual, limpar antigos
//

import Foundation
import AVFoundation
import UIKit
import Photos
import Combine

struct VideoClip: Identifiable {
    let id = UUID()
    let url: URL
    let captureDate: Date
    let duration: TimeInterval
    var thumbnail: UIImage?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: captureDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: captureDate)
    }
}

class StorageManager: ObservableObject {
    @Published var clips: [VideoClip] = []
    
    private let documentsDirectory: URL
    private let clipsDirectory: URL
    
    var totalDuration: String {
        let total = clips.reduce(0.0) { $0 + $1.duration }
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        clipsDirectory = documentsDirectory.appendingPathComponent("Clips")
        
        createClipsDirectoryIfNeeded()
        loadClips()
    }
    
    // MARK: - Directory Management
    private func createClipsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: clipsDirectory.path) {
            try? FileManager.default.createDirectory(at: clipsDirectory, withIntermediateDirectories: true)
            print("✅ Clips directory created")
        }
    }
    
    // MARK: - Save Clip (✅ CORRIGIDO: Agora salva na galeria)
    func saveClip(url: URL) {
        let filename = "\(Date().timeIntervalSince1970).mov"
        let destination = clipsDirectory.appendingPathComponent(filename)
        
        do {
            // Move file to clips directory
            try FileManager.default.moveItem(at: url, to: destination)
            print("✅ File moved to: \(destination.lastPathComponent)")
            
            // Get video duration
            let asset = AVAsset(url: destination)
            let duration = CMTimeGetSeconds(asset.duration)
            
            // Generate thumbnail
            generateThumbnail(for: destination) { [weak self] thumbnail in
                DispatchQueue.main.async {
                    let clip = VideoClip(
                        url: destination,
                        captureDate: Date(),
                        duration: duration,
                        thumbnail: thumbnail
                    )
                    
                    self?.clips.insert(clip, at: 0)
                    print("✅ Clip added to list: \(clip.formattedTime)")
                    
                    // ✅ CORRIGIDO: Salvar na galeria SEMPRE
                    self?.saveToPhotosLibrary(url: destination)
                }
            }
            
        } catch {
            print("❌ Error saving clip: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load Clips
    private func loadClips() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: clipsDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            print("⚠️ No clips directory or empty")
            return
        }
        
        let videoFiles = files.filter { $0.pathExtension == "mov" || $0.pathExtension == "mp4" }
        print("📂 Found \(videoFiles.count) video files")
        
        for url in videoFiles {
            let asset = AVAsset(url: url)
            let duration = CMTimeGetSeconds(asset.duration)
            
            if let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                generateThumbnail(for: url) { [weak self] thumbnail in
                    DispatchQueue.main.async {
                        let clip = VideoClip(
                            url: url,
                            captureDate: creationDate,
                            duration: duration,
                            thumbnail: thumbnail
                        )
                        self?.clips.append(clip)
                        self?.clips.sort { $0.captureDate > $1.captureDate }
                    }
                }
            }
        }
    }
    
    // MARK: - Thumbnail Generation
    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Save to Photos (✅ CORRIGIDO)
    private func saveToPhotosLibrary(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Photo library access denied")
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if success {
                    print("✅ Video saved to Photos library!")
                } else {
                    print("❌ Error saving to Photos: \(error?.localizedDescription ?? "unknown")")
                }
            }
        }
    }
    
    // MARK: - Compile Videos (✅ CORRIGIDO: Agora funciona de verdade)
    func compileClips(selectedClips: [VideoClip], completion: @escaping (Bool, URL?) -> Void) {
        guard !selectedClips.isEmpty else {
            print("❌ No clips to compile")
            completion(false, nil)
            return
        }
        
        print("🎬 Starting compilation of \(selectedClips.count) clips...")
        
        let composition = AVMutableComposition()
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("❌ Failed to create tracks")
            completion(false, nil)
            return
        }
        
        var currentTime = CMTime.zero
        
        // Sort by capture date
        let sortedClips = selectedClips.sorted { $0.captureDate < $1.captureDate }
        
        for clip in sortedClips {
            let asset = AVAsset(url: clip.url)
            
            do {
                // Add video track
                if let assetVideoTrack = asset.tracks(withMediaType: .video).first {
                    try videoTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: asset.duration),
                        of: assetVideoTrack,
                        at: currentTime
                    )
                    print("✅ Added video track from \(clip.url.lastPathComponent)")
                }
                
                // Add audio track
                if let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
                    try audioTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: asset.duration),
                        of: assetAudioTrack,
                        at: currentTime
                    )
                    print("✅ Added audio track from \(clip.url.lastPathComponent)")
                }
                
                currentTime = CMTimeAdd(currentTime, asset.duration)
            } catch {
                print("❌ Error adding clip to composition: \(error.localizedDescription)")
            }
        }
        
        // Export
        let timestamp = Date().timeIntervalSince1970
        let outputURL = documentsDirectory.appendingPathComponent("Compiled_\(Int(timestamp)).mp4")
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("❌ Failed to create export session")
            completion(false, nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        print("🎬 Exporting to: \(outputURL.lastPathComponent)")
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    print("✅ Export completed successfully!")
                    
                    // Save to Photos library
                    self.saveToPhotosLibrary(url: outputURL)
                    
                    completion(true, outputURL)
                } else {
                    print("❌ Export failed: \(exportSession.error?.localizedDescription ?? "unknown")")
                    completion(false, nil)
                }
            }
        }
    }
    
    // MARK: - Delete Clip (✅ CORRIGIDO)
    func deleteClip(_ clip: VideoClip) {
        do {
            try FileManager.default.removeItem(at: clip.url)
            clips.removeAll { $0.id == clip.id }
            print("✅ Deleted clip: \(clip.url.lastPathComponent)")
        } catch {
            print("❌ Error deleting clip: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Multiple Clips (✅ NOVO)
    func deleteClips(_ clipsToDelete: [VideoClip]) {
        for clip in clipsToDelete {
            deleteClip(clip)
        }
    }
    
    // MARK: - Clear Old Clips (✅ CORRIGIDO: Agora funciona)
    func clearOldClips(olderThan days: Int) {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            print("❌ Failed to calculate cutoff date")
            return
        }
        
        print("🗑️ Clearing clips older than \(days) days (before \(cutoffDate))")
        
        let oldClips = clips.filter { $0.captureDate < cutoffDate }
        print("   Found \(oldClips.count) old clips to delete")
        
        for clip in oldClips {
            deleteClip(clip)
        }
        
        print("✅ Cleared \(oldClips.count) old clips")
    }
    
    // MARK: - Clear ALL Clips (✅ NOVO)
    func clearAllClips() {
        print("🗑️ Clearing ALL clips (\(clips.count) total)")
        
        let allClips = clips
        for clip in allClips {
            deleteClip(clip)
        }
        
        print("✅ All clips cleared")
    }
    
    // MARK: - Upload Clips Separately (✅ NOVO)
    func uploadClipsSeparately(_ clipsToUpload: [VideoClip], completion: @escaping (Bool) -> Void) {
        print("📤 Uploading \(clipsToUpload.count) clips separately...")
        
        // Save each to Photos library
        for clip in clipsToUpload {
            saveToPhotosLibrary(url: clip.url)
        }
        
        print("✅ All clips saved to Photos library")
        completion(true)
    }
}
