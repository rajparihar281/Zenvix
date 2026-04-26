import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zenvix/features/pdf_page_manager/models/pdf_page_item.dart';

class PdfPageManagerService {
  Future<List<PdfPageItem>> getPdfPages(Uint8List pdfData) async {
    final pages = <PdfPageItem>[];
    var index = 0;

    await for (final page in Printing.raster(pdfData)) {
      final pngBytes = await page.toPng();
      pages.add(
        PdfPageItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_$index',
          originalIndex: index,
          thumbnailData: pngBytes,
        ),
      );
      index++;
    }

    return pages;
  }

  Future<String> exportPdf({
    required Uint8List originalPdfData,
    required List<PdfPageItem> finalPages,
    required String desiredName,
  }) async {
    final originalDoc = PdfDocument(inputBytes: originalPdfData);
    final newDoc = PdfDocument();

    for (var pageItem in finalPages) {
      final oldPage = originalDoc.pages[pageItem.originalIndex];
      final newPage = newDoc.pages.add();

      final totalAngle =
          (pageItem.rotationAngle + _getAngleValue(oldPage.rotation)) % 360;
      newPage.rotation = _getRotateAngle(totalAngle);

      final template = oldPage.createTemplate();
      newPage.graphics.drawPdfTemplate(template, Offset(0, 0));
    }

    final bytes = newDoc.saveSync();
    originalDoc.dispose();
    newDoc.dispose();

    return _saveToDevice(Uint8List.fromList(bytes), desiredName);
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

  Future<String> _saveToDevice(Uint8List data, String desiredName) async {
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
