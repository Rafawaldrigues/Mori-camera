// LISTAGEM E GERENCIAMENTO DOS CLIPES SALVOS.
// Usar para: ler os arquivos de vídeo salvos na pasta de clipes (via
// StorageService), retornar uma lista ordenada (ex: por data), e oferecer
// operações como deletar um clipe ou renomear.
//
// Não acessa File/Directory diretamente — delega isso ao StorageService,
// mantendo a responsabilidade de I/O em um único lugar.

import '../../../services/storage_service.dart';

class ClipsRepository {
  final StorageService storageService;

  ClipsRepository({required this.storageService});

  /// Retorna a lista de clipes salvos, ordenados do mais recente para o
  /// mais antigo.
  Future<List<String>> listClips() async {
    return storageService.listSavedClips();
  }

  /// Remove um clipe pelo caminho do arquivo.
  Future<void> deleteClip(String filePath) async {
    await storageService.deleteClip(filePath);
  }
}
