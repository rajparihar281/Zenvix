import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/my_file_item.dart';

/// Handles file system operations for "My Files".
class MyFilesService {
  /// Scans the application documents directory for generated PDFs.
  Future<List<MyFileItem>> getGeneratedFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final List<MyFileItem> items = [];

    if (!await dir.exists()) return items;

    final entities = dir.listSync();
    for (var entity in entities) {
      if (entity is File) {
        final name = entity.path.split('/').last.split('\\').last;
        // Check if it's a PDF. We also use the Zenvix_ prefix as a soft filter if needed,
        // but any PDF in the app's sandbox is likely ours.
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
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Renames a file in the file system.
  Future<MyFileItem> renameFile(String path, String newName) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    if (!newName.toLowerCase().endsWith('.pdf')) {
      newName += '.pdf';
    }

    final dirPath = file.parent.path;
    final newPath = '$dirPath/$newName';

    final newFile = await file.rename(newPath);
    return MyFileItem.fromFile(newFile);
  }
}
