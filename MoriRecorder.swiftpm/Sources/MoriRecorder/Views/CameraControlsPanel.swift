import SwiftUI

enum CaptureAspect: String, CaseIterable, Identifiable {
    case wide = "16:9", standard = "4:3", square = "1:1"
    var id: String { rawValue }
    func ratio(portrait: Bool) -> CGFloat {
        let landscape: CGFloat
        switch self {
        case .wide: landscape = 16.0 / 9.0
        case .standard: landscape = 4.0 / 3.0
        case .square: landscape = 1
        }
        return portrait ? 1 / landscape : landscape
    }
}

struct CameraControlsPanel: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var schedulerService: SchedulerService

    var body: some View {
        VStack(spacing: 10) {
            Text("Zoom · óptico/digital").font(.caption)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(cameraManager.zoomOptions, id: \.self) { zoom in
                        Button {
                            cameraManager.setZoom(zoom)
                        } label: {
                            Text(String(format: zoom.rounded() == zoom ? "%.0fx" : "%.1fx", Double(zoom)))
                                .font(.system(size: 16, weight: .semibold))
                                .padding(10)
                                .background(abs(cameraManager.zoom - zoom) < 0.05 ? Theme.lavender : Color.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .accessibilityLabel("Zoom \(zoom, specifier: "%.1f") vezes")
                    }
                }
            }
            Picker("Proporção", selection: $cameraManager.aspectRatio) {
                ForEach(CaptureAspect.allCases) { aspect in
                    Text(aspect.rawValue).tag(aspect)
                }
            }
            .pickerStyle(.segmented)
            HStack {
                Image(systemName: "plusminus.circle")
                Slider(value: Binding(get: { cameraManager.exposure }, set: { cameraManager.setExposure($0) }),
                       in: cameraManager.exposureRange)
                    .accessibilityLabel("Exposição")
                Text(String(format: "%+.1f EV", cameraManager.exposure))
                    .font(.caption.monospacedDigit())
                Button("Zerar") { cameraManager.setExposure(0) }
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(12)
        .background(Color.black.opacity(0.65).cornerRadius(16))
        .disabled(!cameraManager.isSessionReady || schedulerService.isActive || cameraManager.isRecording)
    }
}
