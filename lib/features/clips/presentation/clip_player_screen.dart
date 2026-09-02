// TELA DE REPRODUÇÃO DE UM CLIPE INDIVIDUAL.
// Usar para: reproduzir o vídeo selecionado na lista (usando o pacote
// video_player), com controles básicos de play/pause e possivelmente
// opção de compartilhar/deletar o clipe.

import 'package:flutter/material.dart';

class ClipPlayerScreen extends StatelessWidget {
  final String clipPath;

  const ClipPlayerScreen({super.key, required this.clipPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reproduzindo clipe')),
      body: Center(
        child: Text('TODO: reproduzir vídeo em $clipPath com video_player'),
      ),
    );
  }
}
