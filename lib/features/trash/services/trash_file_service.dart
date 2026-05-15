import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TrashFileService {
  Future<Directory> get _trashDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final trashDir = Directory(p.join(appDir.path, '.trash'));
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
    }
    return trashDir;
  }

  Future<String> moveToTrash(String originalPath) async {
    final originalFile = File(originalPath);
    if (!await originalFile.exists()) {
      throw Exception('File not found: $originalPath');
    }

    final trashDir = await _trashDirectory;
    final fileExtension = p.extension(originalPath);
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final newFileName = '$uniqueId$fileExtension';
    final trashedPath = p.join(trashDir.path, newFileName);

    await originalFile.copy(trashedPath);
    await originalFile.delete();

    return trashedPath;
  }

  Future<void> restoreFile(String trashedPath, String originalPath) async {
    final trashedFile = File(trashedPath);
    if (!await trashedFile.exists()) {
      throw Exception('Trashed file not found: $trashedPath');
    }

    final originalDir = Directory(p.dirname(originalPath));
    if (!await originalDir.exists()) {
      await originalDir.create(recursive: true);
    }

    await trashedFile.copy(originalPath);
    await trashedFile.delete();
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearTrashDirectory() async {
    final trashDir = await _trashDirectory;
    if (await trashDir.exists()) {
      await trashDir.delete(recursive: true);
      await trashDir.create(recursive: true);
    }
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}
