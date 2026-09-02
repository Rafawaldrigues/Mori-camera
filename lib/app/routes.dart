// DEFINIÇÃO CENTRAL DE ROTAS NOMEADAS.
// Usar para: mapear strings de rota (ex: '/camera', '/clips') para as telas
// correspondentes. Evita usar Navigator.push direto com MaterialPageRoute
// espalhado pelo código — tudo fica registrado aqui.
//
// Ao criar uma nova tela em features/, adicione a rota dela neste arquivo.

import 'package:flutter/material.dart';
import '../features/camera/presentation/camera_screen.dart';
import '../features/clips/presentation/clips_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class Routes {
  static const String camera = '/camera';
  static const String clips = '/clips';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> all = {
    camera: (context) => const CameraScreen(),
    clips: (context) => const ClipsListScreen(),
    settings: (context) => const SettingsScreen(),
  };
}
