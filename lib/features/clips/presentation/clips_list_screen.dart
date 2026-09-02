// TELA DE LISTAGEM DOS CLIPES GRAVADOS.
// Usar para: mostrar em grade ou lista todos os clipes salvos localmente
// (usando ClipsRepository.listClips()), com thumbnail, duração e opção de
// abrir no clip_player_screen.dart ou deletar.

import 'package:flutter/material.dart';

class ClipsListScreen extends StatelessWidget {
  const ClipsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clipes gravados')),
      body: const Center(
        child: Text('TODO: listar clipes usando ClipsRepository'),
      ),
    );
  }
}
