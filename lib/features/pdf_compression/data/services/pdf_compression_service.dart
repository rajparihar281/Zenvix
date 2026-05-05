import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zenvix/features/pdf_compression/domain/models/compression_options.dart';

/// Compresses a PDF by rasterizing each page, re-encoding as JPEG at the
/// target quality, and assembling a new document from those images.
class PdfCompressionService {
  /// Compresses [pdfData] at the quality defined by [level].
  ///
  /// Progress is reported via [onProgress] as a fraction (0.0 – 1.0).
  Future<Uint8List> compress({
    required Uint8List pdfData,
    required CompressionLevel level,
    void Function(double)? onProgress,
  }) async {
    // Read original page dimensions so we can recreate them exactly.
    final sourceDoc = PdfDocument(inputBytes: pdfData);
    final pageCount = sourceDoc.pages.count;
    final pageSizes = <Size>[];
    for (var i = 0; i < pageCount; i++) {
      final p = sourceDoc.pages[i];
      pageSizes.add(p.size);
    }
    sourceDoc.dispose();

    final dpi = _dpiForLevel(level);
    var processed = 0;

    final newDoc = PdfDocument();
    // Syncfusion adds a default blank page; remove it.
    newDoc.pages.removeAt(0);

    await for (final rasterPage in Printing.raster(
      pdfData,
      dpi: dpi.toDouble(),
    )) {
      final pngBytes = await rasterPage.toPng();

      // Heavy PNG → JPEG transcoding runs off the UI thread.
      final jpegBytes = await compute(
        _reEncodeToJpeg,
        _EncodeParams(pngBytes, level.jpegQuality),
      );

      final size = processed < pageSizes.length ? pageSizes[processed] : pageSizes.last;
      newDoc.pageSettings.size = size;
      newDoc.pageSettings.margins.all = 0;
      final page = newDoc.pages.add();
      final bitmap = PdfBitmap(jpegBytes);
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

      processed++;
      onProgress?.call(processed / pageCount);
    }

    final result = Uint8List.fromList(newDoc.saveSync());
    newDoc.dispose();
    return result;
  }

  /// Estimates the compressed size without performing the full operation.
  int estimateCompressedSize({
    required int originalSize,
    required CompressionLevel level,
  }) {
    const imageRatio = 0.6;
    final qualityFactor = level.jpegQuality / 100;
    final estimatedImageBytes = (originalSize * imageRatio * qualityFactor)
        .round();
    final nonImageBytes = (originalSize * (1 - imageRatio)).round();
    return estimatedImageBytes + nonImageBytes;
  }

  /// Saves bytes to the platform's download directory.
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

  // ── Private helpers ──────────────────────────────────────────────────

  int _dpiForLevel(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 200;
      case CompressionLevel.medium:
        return 150;
      case CompressionLevel.high:
        return 100;
    }
  }

// ── Top-level isolate functions ──────────────────────────────────────────

/// Re-encodes PNG bytes to JPEG at the given quality.
/// Must be a top-level function for [compute].
Uint8List _reEncodeToJpeg(_EncodeParams params) {
  final decoded = img.decodePng(params.pngBytes);
  if (decoded == null) {
    return params.pngBytes;
  }
  return Uint8List.fromList(img.encodeJpg(decoded, quality: params.quality));
}

class _EncodeParams {
  const _EncodeParams(this.pngBytes, this.quality);

  final Uint8List pngBytes;
  final int quality;
}
