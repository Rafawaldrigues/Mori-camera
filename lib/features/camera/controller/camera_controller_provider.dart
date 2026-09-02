// GERENCIAMENTO DE ESTADO DA TELA DE CÂMERA.
// Usar para: expor o estado de gravação (gravando/parado, tempo decorrido,
// lista de clipes da sessão atual) para a UI, usando o gerenciador de
// estado escolhido (Provider, Riverpod ou Bloc — ajuste a implementação
// conforme a escolha do projeto).
//
// Este arquivo é o "meio de campo" entre camera_screen.dart (UI) e
// camera_repository.dart (lógica de gravação).

// TODO: implementar conforme o state management escolhido.
// Exemplo com ChangeNotifier (Provider):
//
// import 'package:flutter/foundation.dart';
// import '../data/camera_repository.dart';
//
// class CameraControllerProvider extends ChangeNotifier {
//   final CameraRepository repository;
//   bool isRecording = false;
//
//   CameraControllerProvider(this.repository);
//
//   Future<void> toggleRecording() async {
//     if (isRecording) {
//       await repository.stopSession();
//     } else {
//       await repository.startSession();
//     }
//     isRecording = !isRecording;
//     notifyListeners();
//   }
// }
