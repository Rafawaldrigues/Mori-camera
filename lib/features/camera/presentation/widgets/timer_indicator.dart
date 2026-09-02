// INDICADOR DE TEMPO DO CLIPE ATUAL.
// Usar para: mostrar visualmente (texto ou barra de progresso) quanto
// tempo falta para o corte automático do clipe em gravação, baseado na
// duração configurada em AppConstants.defaultClipDurationSeconds.

import 'package:flutter/material.dart';

class TimerIndicator extends StatelessWidget {
  final Duration elapsed;
  final Duration totalDuration;

  const TimerIndicator({
    super.key,
    required this.elapsed,
    required this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalDuration - elapsed;
    return Text(
      '${remaining.inSeconds}s',
      style: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }
}
