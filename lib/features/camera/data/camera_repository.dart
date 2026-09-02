// LÓGICA CENTRAL DE GRAVAÇÃO E SEGMENTAÇÃO DE VÍDEO.
// Usar para: encapsular toda a interação com o CameraController (iniciar
// preview, começar gravação, parar gravação, mover o arquivo gravado para
// a pasta de clipes). É AQUI que você decide a estratégia de corte:
//
//   1) Start/stop em loop (mais simples, pode ter gap entre clipes), ou
//   2) Gravação contínua + corte posterior via video_segmenter_service.dart
//
// A UI (camera_screen.dart) não deve saber COMO a gravação é feita — ela
// só chama métodos como startSession() / stopSession() daqui.

import 'dart:async';
import 'package:camera/camera.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/file_naming.dart';
import '../../../services/storage_service.dart';

class CameraRepository {
  final CameraController controller;
  final StorageService storageService;
  Timer? _segmentTimer;

  CameraRepository({
    required this.controller,
    required this.storageService,
  });

  /// Inicia uma sessão de gravação que corta automaticamente em clipes,
  /// a cada [clipDurationSeconds]. Chame stopSession() para encerrar tudo.
  Future<void> startSession({
    int clipDurationSeconds = AppConstants.defaultClipDurationSeconds,
  }) async {
    await _recordSingleClip();
    _segmentTimer = Timer.periodic(
      Duration(seconds: clipDurationSeconds),
      (_) async {
        await controller.stopVideoRecording();
        await _saveLastClip();
        await _recordSingleClip();
      },
    );
  }

  /// Para a sessão de gravação e salva o último clipe em andamento.
  Future<void> stopSession() async {
    _segmentTimer?.cancel();
    if (controller.value.isRecordingVideo) {
      await controller.stopVideoRecording();
      await _saveLastClip();
    }
  }

  Future<void> _recordSingleClip() async {
    await controller.prepareForVideoRecording();
    await controller.startVideoRecording();
  }

  Future<void> _saveLastClip() async {
    final XFile rawFile = await controller.stopVideoRecording();
    final fileName = FileNaming.generateClipFileName();
    await storageService.saveClip(rawFile, fileName);
  }
}
