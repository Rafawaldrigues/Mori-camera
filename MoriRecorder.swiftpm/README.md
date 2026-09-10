# MoriRecorder — Swift Playgrounds

Projeto convertido para `.swiftpm`, pronto para abrir no Swift Playgrounds no iPad.

## Correção da câmera 0.5x

A versão anterior usava `DiscoverySession.devices.first`, que pode selecionar uma câmera virtual em vez da câmera Wide Angle física. No iPhone 15 isso pode fazer `videoZoomFactor = 1.0` resultar na lente ultra-wide (0.5x).

A versão corrigida seleciona explicitamente:

`AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: ...)`

Também reseta o zoom para `1.0` ao inicializar e encerra uma sessão anterior antes de recriá-la.

## iPad

Abra este `.swiftpm` no Swift Playgrounds e execute no iPad. O pacote mantém o código original e aplica a correção da seleção da câmera.
