// SERVIÇO DE ARMAZENAMENTO LOCAL DOS CLIPES.
// Usar para: centralizar TODO o acesso ao sistema de arquivos do celular
// (via path_provider + dart:io File/Directory). Isso inclui:
//   - encontrar/criar a pasta de clipes dentro do diretório de documentos
//   - mover/copiar o arquivo temporário gravado pelo CameraController
//     para a pasta definitiva de clipes
//   - listar os clipes salvos
//   - deletar um clipe
//
// Nenhuma outra parte do app deve mexer em File/Directory diretamente —
// tudo passa por aqui, facilitando trocar a estratégia de armazenamento
// no futuro (ex: se um dia precisar migrar para armazenamento externo).

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';

class StorageService {
  /// Retorna (criando se necessário) o diretório onde os clipes são salvos.
  Future<Directory> _clipsDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final clipsDir = Directory(p.join(baseDir.path, AppConstants.clipsFolderName));
    if (!await clipsDir.exists()) {
      await clipsDir.create(recursive: true);
    }
    return clipsDir;
  }

  /// Move o arquivo temporário gravado (XFile do CameraController) para a
  /// pasta definitiva de clipes, com o nome já gerado por FileNaming.
  Future<File> saveClip(XFile rawFile, String fileName) async {
    final clipsDir = await _clipsDirectory();
    final destinationPath = p.join(clipsDir.path, fileName);
    return File(rawFile.path).copy(destinationPath);
  }

  /// Lista os caminhos completos de todos os clipes salvos, mais recentes
  /// primeiro.
  Future<List<String>> listSavedClips() async {
    final clipsDir = await _clipsDirectory();
    final files = clipsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(AppConstants.videoFileExtension))
        .toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.map((f) => f.path).toList();
  }

  /// Remove um clipe do armazenamento local.
  Future<void> deleteClip(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
