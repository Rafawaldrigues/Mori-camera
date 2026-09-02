// SEGMENTAÇÃO DE VÍDEO VIA FFMPEG (ESTRATÉGIA ALTERNATIVA DE CORTE).
// Usar para: SE você optar pela abordagem de "gravar contínuo e cortar
// depois" (em vez de start/stop em loop), este serviço usa o pacote
// ffmpeg_kit_flutter para dividir um arquivo de vídeo único em vários
// clipes de duração fixa, com precisão de frame.
//
// Só implemente/inclua este arquivo se a precisão do corte for crítica
// para o seu caso de uso — ele adiciona peso ao app (binário do ffmpeg).

// Exemplo de uso (pseudo-código, requer o pacote ffmpeg_kit_flutter):
//
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
//
// class VideoSegmenterService {
//   Future<void> splitIntoSegments({
//     required String inputPath,
//     required String outputDir,
//     required int segmentDurationSeconds,
//   }) async {
//     final command =
//         '-i $inputPath -c copy -f segment -segment_time '
//         '$segmentDurationSeconds -reset_timestamps 1 '
//         '$outputDir/clip_%03d.mp4';
//     await FFmpegKit.execute(command);
//   }
// }
