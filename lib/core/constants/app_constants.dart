// CONSTANTES GLOBAIS DO APP.
// Usar para: valores fixos reutilizados em várias partes do código, como
// duração padrão de cada clipe gravado, extensão dos arquivos de vídeo,
// nome da pasta onde os clipes são salvos, resolução padrão da câmera, etc.
//
// Evita "números mágicos" espalhados pelo código — se precisar mudar a
// duração do corte, muda aqui e reflete em todo o app.

class AppConstants {
  // Duração de cada segmento/clipe gravado, em segundos.
  static const int defaultClipDurationSeconds = 15;

  // Nome da subpasta (dentro do diretório de documentos do app) onde os
  // clipes ficam salvos.
  static const String clipsFolderName = 'clips';

  // Extensão/formato padrão dos arquivos de vídeo gravados.
  static const String videoFileExtension = '.mp4';

  // Prefixo usado na geração de nomes de arquivo (ver file_naming.dart).
  static const String clipFilePrefix = 'clip';
}
