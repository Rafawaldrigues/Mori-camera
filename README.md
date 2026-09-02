# Meu App Câmera

App Flutter (Android + iOS) que grava vídeo em sessões, cortando
automaticamente em clipes de duração pré-definida, salvos na memória
local do dispositivo (sem backend, sem banco de dados).

## Estrutura do projeto

- `lib/main.dart` — bootstrap do app.
- `lib/app/` — configuração do MaterialApp, tema e rotas.
- `lib/core/` — constantes, tema visual e utilitários (nomenclatura de
  arquivo, permissões).
- `lib/features/camera/` — tudo relacionado à gravação (repository, tela,
  widgets, controller de estado).
- `lib/features/clips/` — listagem e reprodução dos clipes salvos.
- `lib/features/settings/` — configurações do usuário (opcional).
- `lib/services/` — acesso a sistema de arquivos (`storage_service.dart`)
  e, opcionalmente, segmentação via ffmpeg
  (`video_segmenter_service.dart`).
- `test/` — testes unitários espelhando a estrutura de `lib/`.

## Próximos passos

1. Rodar `flutter create .` na raiz para gerar as pastas nativas
   completas de `android/` e `ios/` (os `.gitkeep` aqui são só
   placeholders).
2. Rodar `flutter pub get` para instalar as dependências do
   `pubspec.yaml`.
3. Configurar permissões nativas:
   - **Android**: `android/app/src/main/AndroidManifest.xml` — adicionar
     `CAMERA` e `RECORD_AUDIO`.
   - **iOS**: `ios/Runner/Info.plist` — adicionar
     `NSCameraUsageDescription` e `NSMicrophoneUsageDescription`.
4. Implementar a lógica em `camera_repository.dart` (já tem um
   esqueleto funcional da estratégia de start/stop em loop).
5. Decidir entre gravação em segmentos direto ou gravação contínua +
   corte via ffmpeg (ver comentário em `video_segmenter_service.dart`).
