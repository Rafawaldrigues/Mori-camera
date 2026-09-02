// GERENCIAMENTO DE PERMISSÕES (CÂMERA, MICROFONE, ARMAZENAMENTO).
// Usar para: verificar e solicitar as permissões necessárias antes de
// abrir a câmera ou gravar vídeo, usando o pacote permission_handler.
// Chame PermissionsHelper.requestCameraPermissions() antes de inicializar
// o CameraController na camera_screen.dart.
//
// Lembrete: no iOS, adicione as chaves NSCameraUsageDescription e
// NSMicrophoneUsageDescription no Info.plist, ou o app vai crashar ao
// pedir permissão.

import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Solicita permissão de câmera e microfone (necessário para gravar
  /// vídeo com áudio). Retorna true se ambas foram concedidas.
  static Future<bool> requestCameraPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }
}
