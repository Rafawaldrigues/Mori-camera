// PONTO DE ENTRADA DO APP.
// Usar para: inicializar bindings do Flutter, garantir que as câmeras
// disponíveis sejam carregadas (availableCameras()) antes de rodar o app,
// e chamar runApp() com o widget raiz (MyApp).
//
// Não colocar lógica de negócio aqui — apenas bootstrap.

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'app/app.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}
