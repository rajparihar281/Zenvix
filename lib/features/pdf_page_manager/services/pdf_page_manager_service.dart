import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/pdf_page_item.dart';

class PdfPageManagerService {
  /// Rasterizes PDF pages into thumbnails using printing package.
  Future<List<PdfPageItem>> getPdfPages(Uint8List pdfData) async {
    final List<PdfPageItem> pages = [];
    int index = 0;

    await for (final page in Printing.raster(pdfData, dpi: 72)) {
      final pngBytes = await page.toPng();
      pages.add(PdfPageItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_$index',
        originalIndex: index,
        thumbnailData: pngBytes,
      ));
      index++;
    }

    return pages;
  }

  /// Exports the selected pages into a new PDF document.
  Future<String> exportPdf({
    required Uint8List originalPdfData,
    required List<PdfPageItem> finalPages,
    required String desiredName,
  }) async {
    final PdfDocument originalDoc = PdfDocument(inputBytes: originalPdfData);
    final PdfDocument newDoc = PdfDocument();

    for (var pageItem in finalPages) {
      final oldPage = originalDoc.pages[pageItem.originalIndex];
      final newPage = newDoc.pages.add();

      // Apply rotation to new page based on user edits + original rotation
      // Syncfusion uses enum PdfPageRotateAngle
      final int totalAngle = (pageItem.rotationAngle + _getAngleValue(oldPage.rotation)) % 360;
      newPage.rotation = _getRotateAngle(totalAngle);

      final template = oldPage.createTemplate();
      newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
    }

    final List<int> bytes = newDoc.saveSync();
    originalDoc.dispose();
    newDoc.dispose();

    return await _saveToDevice(Uint8List.fromList(bytes), desiredName);
  }

  int _getAngleValue(PdfPageRotateAngle angle) {
    switch (angle) {
      case PdfPageRotateAngle.rotateAngle90:
        return 90;
      case PdfPageRotateAngle.rotateAngle180:
        return 180;
      case PdfPageRotateAngle.rotateAngle270:
        return 270;
      case PdfPageRotateAngle.rotateAngle0:
      return 0;
    }
  }

  PdfPageRotateAngle _getRotateAngle(int angle) {
    switch (angle) {
      case 90:
        return PdfPageRotateAngle.rotateAngle90;
      case 180:
        return PdfPageRotateAngle.rotateAngle180;
      case 270:
        return PdfPageRotateAngle.rotateAngle270;
      case 0:
      default:
        return PdfPageRotateAngle.rotateAngle0;
    }
  }

  /// Saves the merged PDF to a public directory (Downloads on Android, Documents on iOS).
  Future<String> _saveToDevice(Uint8List data, String desiredName) async {
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
    final file = File(targetPath);
    await file.writeAsBytes(data);
    return file.path;
  }
}
