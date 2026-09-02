// WIDGET RAIZ DO APP (MaterialApp).
// Usar para: configurar tema global (AppTheme), rotas nomeadas (routes.dart)
// e definir qual tela é a home inicial (provavelmente CameraScreen).
//
// Mantenha este arquivo enxuto — apenas configuração, nada de UI real aqui.

import 'package:flutter/material.dart';
import 'routes.dart';
import '../core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App Câmera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.camera,
      routes: Routes.all,
    );
  }
}
