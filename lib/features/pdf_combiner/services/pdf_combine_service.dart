import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

/// Merges multiple PDF files into a single document.
class PdfCombineService {
  /// Merge [paths] into one PDF. Returns the output file path.
  Future<String> combinePdfs(List<String> paths) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${dir.path}/Zenvix_Merged_$timestamp.pdf';

    await PdfCombiner.mergeMultiplePDFs(
      inputPaths: paths,
      outputPath: outputPath,
    );

    return outputPath;
  }

  /// Saves the merged PDF to a public directory (Downloads on Android, Documents on iOS).
  Future<String> saveToDevice(String sourcePath, String desiredName) async {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw Exception('Source file does not exist.');
    }

    // Add .pdf extension if not present - use local variable
    var finalName = desiredName;
    if (!finalName.toLowerCase().endsWith('.pdf')) {
      finalName += '.pdf';
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not find directory to save the file.');
    }

    // Handle duplicate filenames to avoid overwriting
    final targetPath = await _getUniqueFilePath(directory.path, finalName);
    final savedFile = await file.copy(targetPath);
    return savedFile.path;
  }

  /// Helper method to generate unique file path if file already exists
  Future<String> _getUniqueFilePath(
    String directoryPath,
    String fileName,
  ) async {
    var finalName = fileName;
    var targetPath = '$directoryPath/$finalName';
    final file = File(targetPath);

    if (!file.existsSync()) {
      return targetPath;
    }

    // If file exists, add a number suffix
    final nameWithoutExt = fileName.substring(0, fileName.length - 4);
    var counter = 1;

    do {
      final newName = '${nameWithoutExt}_$counter.pdf';
      targetPath = '$directoryPath/$newName';
      finalName = newName;
      counter++;
    } while (File(targetPath).existsSync());

    return targetPath;
  }
}
