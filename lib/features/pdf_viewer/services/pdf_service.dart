import 'dart:io';

class PdfService {
  bool fileExists(String path) {
    final file = File(path);
    return file.existsSync();
  }

  String getFileName(String path) => path.split('/').last;
  Future<File> getPdfFile(String path) async => File(path);
}
