// TELA PRINCIPAL DE GRAVAÇÃO.
// Usar para: mostrar o preview da câmera (CameraPreview), o botão de
// gravar (record_button.dart) e o indicador do tempo restante do clipe
// atual (timer_indicator.dart).
//
// Esta tela deve delegar toda a lógica de gravação para o
// CameraRepository/CameraControllerProvider — aqui só fica a montagem
// visual e a resposta a eventos de toque.

import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'TODO: CameraPreview + RecordButton + TimerIndicator',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
