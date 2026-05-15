import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TrashFileService {
  Future<Directory> get _trashDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final trashDir = Directory(p.join(appDir.path, '.trash'));
    if (!trashDir.existsSync()) {
      trashDir.createSync(recursive: true);
    }
    return trashDir;
  }

  Future<String> moveToTrash(String originalPath) async {
    final originalFile = File(originalPath);
    if (!originalFile.existsSync()) {
      throw Exception('File not found: $originalPath');
    }

    final trashDir = await _trashDirectory;
    final fileExtension = p.extension(originalPath);
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final newFileName = '$uniqueId$fileExtension';
    final trashedPath = p.join(trashDir.path, newFileName);

    originalFile
      ..copySync(trashedPath)
      ..deleteSync();

    return trashedPath;
  }

  Future<void> restoreFile(String trashedPath, String originalPath) async {
    final trashedFile = File(trashedPath);
    if (!trashedFile.existsSync()) {
      throw Exception('Trashed file not found: $trashedPath');
    }

    final originalDir = Directory(p.dirname(originalPath));
    if (!originalDir.existsSync()) {
      originalDir.createSync(recursive: true);
    }

    trashedFile
      ..copySync(originalPath)
      ..deleteSync();
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<void> clearTrashDirectory() async {
    final trashDir = await _trashDirectory;
    if (trashDir.existsSync()) {
      trashDir
        ..deleteSync(recursive: true)
        ..createSync(recursive: true);
    }
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return 0;
  }
}
