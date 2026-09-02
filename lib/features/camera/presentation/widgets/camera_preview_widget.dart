// WIDGET DE PREVIEW DA CÂMERA.
// Usar para: envolver o CameraController.buildPreview() (ou CameraPreview
// do pacote camera) em um widget reutilizável, tratando aspect ratio e
// estados de carregamento/erro (ex: câmera ainda não inicializada).

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }
}
