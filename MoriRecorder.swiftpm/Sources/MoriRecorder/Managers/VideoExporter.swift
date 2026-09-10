import AVFoundation

/// Shared local export path for camera crops and gallery combinations.
enum VideoExporter {
    static func export(urls: [URL], aspect: CGFloat? = nil) async throws -> URL {
        guard !urls.isEmpty else { throw failure("Selecione pelo menos um clipe.") }
        let composition = AVMutableComposition()
        guard let video = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw failure("Não foi possível criar a faixa de vídeo.")
        }
        var cursor = CMTime.zero
        var instructions: [AVMutableVideoCompositionInstruction] = []
        var canvas: CGSize?
        for url in urls {
            let asset = AVURLAsset(url: url)
            guard let source = try await asset.loadTracks(withMediaType: .video).first else {
                throw failure("O clipe \(url.lastPathComponent) não contém vídeo.")
            }
            let range = try await source.load(.timeRange)
            guard range.duration.seconds.isFinite, range.duration.seconds > 0 else {
                throw failure("O clipe \(url.lastPathComponent) tem duração inválida.")
            }
            let size = try await source.load(.naturalSize)
            let transform = try await source.load(.preferredTransform)
            let bounds = CGRect(origin: .zero, size: size).applying(transform)
            guard bounds.width > 0, bounds.height > 0 else { throw failure("Dimensões de vídeo inválidas.") }
            if canvas == nil {
                var width = bounds.width
                var height = bounds.height
                if let aspect {
                    if width / height > aspect { width = height * aspect }
                    else { height = width / aspect }
                }
                canvas = CGSize(width: max(2, floor(width / 2) * 2), height: max(2, floor(height / 2) * 2))
            }
            let renderSize = canvas!
            try video.insertTimeRange(range, of: source, at: cursor)
            // Preserve audio's actual time range, including any initial offset.
            if let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first {
                let audioRange = try await sourceAudio.load(.timeRange)
                let overlap = CMTimeRangeGetIntersection(range, otherRange: audioRange)
                if overlap.duration.seconds > 0 {
                    guard let audio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                        throw failure("Não foi possível criar a faixa de áudio.")
                    }
                    try audio.insertTimeRange(overlap, of: sourceAudio,
                        at: CMTimeAdd(cursor, CMTimeSubtract(overlap.start, range.start)))
                }
            }
            // Crops fill the chosen aspect; combinations fit each clip without stretching.
            let sx = renderSize.width / bounds.width
            let sy = renderSize.height / bounds.height
            let scale = aspect == nil ? min(sx, sy) : max(sx, sy)
            let finalTransform = transform
                .concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
                .concatenating(CGAffineTransform(scaleX: scale, y: scale))
                .concatenating(CGAffineTransform(
                    translationX: (renderSize.width - bounds.width * scale) / 2,
                    y: (renderSize.height - bounds.height * scale) / 2))
            let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: video)
            layer.setTransform(finalTransform, at: cursor)
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: cursor, duration: range.duration)
            instruction.layerInstructions = [layer]
            instructions.append(instruction)
            cursor = CMTimeAdd(cursor, range.duration)
        }
        let edits = AVMutableVideoComposition()
        edits.renderSize = canvas!
        edits.frameDuration = CMTime(value: 1, timescale: 30)
        edits.instructions = instructions
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw failure("Não foi possível iniciar a exportação local.")
        }
        let type: AVFileType = exporter.supportedFileTypes.contains(.mov) ? .mov : .mp4
        guard exporter.supportedFileTypes.contains(type) else { throw failure("Formato de exportação indisponível.") }
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(type == .mov ? "mov" : "mp4")
        exporter.outputURL = output
        exporter.outputFileType = type
        exporter.videoComposition = edits
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            exporter.exportAsynchronously { continuation.resume() }
        }
        guard exporter.status == .completed else {
            try? FileManager.default.removeItem(at: output)
            throw exporter.error ?? failure("A exportação foi interrompida.")
        }
        return output
    }

    static func failure(_ message: String) -> NSError {
        NSError(domain: "MoriRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
