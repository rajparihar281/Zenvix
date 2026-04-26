import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:zenvix/features/my_files/models/my_file_item.dart';

/// Handles file system operations for "My Files".
class MyFilesService {
  /// Scans the application documents directory for generated PDFs.
  Future<List<MyFileItem>> getGeneratedFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final items = <MyFileItem>[];

    if (!dir.existsSync()) {
      return items;
    }

    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        final name = entity.path.split('/').last.split(r'\').last;
        if (name.toLowerCase().endsWith('.pdf')) {
          items.add(MyFileItem.fromFile(entity));
        }
      }
    }

    return items;
  }

  /// Deletes a file from the file system.
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<MyFileItem> renameFile(String path, String newName) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }

    final finalNewName = newName.toLowerCase().endsWith('.pdf')
        ? newName
        : '$newName.pdf';

    final dirPath = file.parent.path;
    final newPath = '$dirPath/$finalNewName';

    final newFile = await file.rename(newPath);
    return MyFileItem.fromFile(newFile);
  }
}
