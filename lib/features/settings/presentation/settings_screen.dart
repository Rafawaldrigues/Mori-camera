// TELA DE CONFIGURAÇÕES (OPCIONAL).
// Usar para: permitir ao usuário ajustar preferências como duração do
// corte de cada clipe, qualidade de gravação (resolução), câmera padrão
// (frontal/traseira). Persistir essas preferências localmente com
// shared_preferences, se necessário.

import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: const Center(
        child: Text('TODO: duração do clipe, qualidade, câmera padrão'),
      ),
    );
  }
}
