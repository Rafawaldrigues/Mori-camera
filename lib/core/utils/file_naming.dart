// GERAÇÃO DE NOMES DE ARQUIVO PARA OS CLIPES.
// Usar para: criar nomes únicos e ordenáveis para cada clipe gravado,
// combinando prefixo + timestamp (ou número sequencial), garantindo que
// os arquivos fiquem em ordem cronológica ao listar a pasta.
//
// Exemplo de nome gerado: clip_2026-09-02_143210.mp4

import '../constants/app_constants.dart';

class FileNaming {
  /// Gera um nome de arquivo único baseado no timestamp atual.
  static String generateClipFileName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${_two(now.month)}-${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    return '${AppConstants.clipFilePrefix}_$timestamp${AppConstants.videoFileExtension}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
