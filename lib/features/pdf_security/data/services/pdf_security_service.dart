import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zenvix/features/pdf_security/domain/models/security_options.dart';

/// Handles PDF encryption, decryption, and permission management
/// using the Syncfusion Flutter PDF library.
class PdfSecurityService {
  /// Adds password protection and permission controls to [pdfData].
  ///
  /// [userPassword] is required for opening the document.
  /// [ownerPassword] is optional; if omitted it defaults to [userPassword].
  Uint8List protect({
    required Uint8List pdfData,
    required String userPassword,
    String? ownerPassword,
    SecurityPermissions permissions = const SecurityPermissions(),
  }) {
    final document = PdfDocument(inputBytes: pdfData);

    document.security
      ..userPassword = userPassword
      ..ownerPassword = ownerPassword ?? userPassword
      ..algorithm = PdfEncryptionAlgorithm.aesx256Bit;

    // Set permission flags.
    document.security.permissions.clear();
    if (permissions.allowPrinting) {
      document.security.permissions.add(PdfPermissionsFlags.print);
    }
    if (permissions.allowCopying) {
      document.security.permissions.add(PdfPermissionsFlags.copyContent);
    }

    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  /// Removes password protection from [pdfData] using the known [password].
  ///
  /// Throws an [Exception] if the password is incorrect.
  Uint8List unlock({required Uint8List pdfData, required String password}) {
    try {
      final document = PdfDocument(inputBytes: pdfData, password: password);

      // Clear all security settings.
      document.security
        ..userPassword = ''
        ..ownerPassword = '';
      document.security.permissions
        ..clear()
        ..addAll([
          PdfPermissionsFlags.print,
          PdfPermissionsFlags.copyContent,
          PdfPermissionsFlags.editContent,
          PdfPermissionsFlags.editAnnotations,
          PdfPermissionsFlags.fillFields,
          PdfPermissionsFlags.assembleDocument,
          PdfPermissionsFlags.accessibilityCopyContent,
          PdfPermissionsFlags.fullQualityPrint,
        ]);

      final bytes = Uint8List.fromList(document.saveSync());
      document.dispose();
      return bytes;
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('password') || message.contains('encrypt')) {
        throw Exception(
          'Incorrect password. Please check your password and try again.',
        );
      }
      rethrow;
    }
  }

  /// Saves processed PDF bytes to the platform's download directory.
  Future<String> saveToDevice(Uint8List data, String desiredName) async {
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

    final targetPath = '${directory.path}/$finalName';
    final file = File(targetPath);
    await file.writeAsBytes(data);
    return file.path;
  }
}
