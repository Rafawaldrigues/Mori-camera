// BOTÃO DE INICIAR/PARAR GRAVAÇÃO.
// Usar para: componente visual do botão circular de gravação, que muda de
// estado (ícone/cor) conforme está gravando ou não. Recebe callbacks
// onStart/onStop via construtor — não deve conter lógica de câmera.

import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CircleAvatar(
        radius: 36,
        backgroundColor: isRecording ? Colors.red : Colors.white,
      ),
    );
  }
}
