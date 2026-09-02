// TEMA VISUAL DO APP.
// Usar para: centralizar cores, tipografia e estilos de componentes
// (ThemeData) usados pelo MaterialApp. Separar do app.dart mantém a
// configuração de estilo isolada e fácil de ajustar sem tocar em lógica.

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark, // apps de câmera geralmente usam tema escuro
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      useMaterial3: true,
    );
  }
}
