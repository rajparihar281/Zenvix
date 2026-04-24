import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
/// Merges multiple PDF files into a single document.
class PdfCombineService {
  /// Merge [paths] into one PDF. Returns the output file path.
  Future<String> combinePdfs(List<String> paths) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${dir.path}/ToolForge_Merged_$timestamp.pdf';

    await PdfCombiner.mergeMultiplePDFs(
      inputPaths: paths,
      outputPath: outputPath,
    );

    return outputPath;
  }

  /// Saves the merged PDF to a public directory (Downloads on Android, Documents on iOS).
  Future<String> saveToDevice(String sourcePath, String desiredName) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Source file does not exist.');
    }

    // Add .pdf extension if not present
    if (!desiredName.toLowerCase().endsWith('.pdf')) {
      desiredName += '.pdf';
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not find directory to save the file.');
    }

    final targetPath = '${directory.path}/$desiredName';
    final savedFile = await file.copy(targetPath);
    return savedFile.path;
  }
}
