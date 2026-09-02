// ITEM VISUAL DE UM CLIPE NA LISTA/GRADE.
// Usar para: componente reutilizável que mostra a thumbnail do clipe,
// nome/timestamp do arquivo, e responde a toque (abrir player) e
// toque-longo (opção de deletar).

import 'package:flutter/material.dart';

class ClipTile extends StatelessWidget {
  final String fileName;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ClipTile({
    super.key,
    required this.fileName,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(fileName),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
