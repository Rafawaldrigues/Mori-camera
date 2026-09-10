// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "MoriRecorder",
    platforms: [.iOS("15.0")],
    products: [
        .iOSApplication(
            name: "MoriRecorder",
            targets: ["MoriRecorder"],
            displayVersion: "1.0",
            bundleVersion: "1",
            iconAssetName: "AppIcon",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .camera(purposeString: "Mori.Recorder precisa acessar a câmera para gravar vídeos automaticamente em intervalos programados."),
                .microphone(purposeString: "Mori.Recorder precisa acessar o microfone para gravar áudio junto com os vídeos."),
                .photoLibraryAdd(purposeString: "Mori.Recorder precisa salvar os vídeos capturados na sua biblioteca de fotos."),
                .photoLibrary(purposeString: "Mori.Recorder precisa acessar sua biblioteca de fotos para gerenciar vídeos capturados.")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "MoriRecorder",
            resources: [.process("Resources")]
        )
    ]
)
