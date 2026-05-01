import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/features/image_to_pdf/models/editable_image.dart';
import 'package:zenvix/features/image_to_pdf/models/pdf_options.dart';
import 'package:zenvix/features/image_to_pdf/services/image_processing_service.dart';

/// Generates a multi-page PDF from a list of [EditableImage]s.
class PdfGenerationService {
  final ImageProcessingService _processingService = ImageProcessingService();

  /// Build and save the PDF to a temporary app-documents path.
  ///
  /// [onProgress] reports a value 0.0–1.0 as each image is processed.
  /// Returns the path to the saved temporary file. Use [StorageService] to
  /// move it to its final destination.
  Future<String> generatePdf({
    required List<EditableImage> images,
    required PdfOptions options,
    void Function(double progress)? onProgress,
  }) async {
    final pdf = pw.Document();

    final pageFormat = _resolvePageFormat(options);

    for (var i = 0; i < images.length; i++) {
      final editableImage = images[i];

      // Process the image (apply edits).
      Uint8List imageBytes;
      if (editableImage.hasEdits) {
        imageBytes = await _processingService.processImage(editableImage);
      } else {
        imageBytes = await _processingService.readFileBytes(
          editableImage.originalPath,
        );
      }

      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(options.marginMm * PdfPageFormat.mm),
          build: (pw.Context context) {
            if (options.scaling == ImageScaling.fill) {
              return pw.Center(
                child: pw.Image(
                  pdfImage,
                  fit: pw.BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            } else {
              return pw.Center(child: pw.Image(pdfImage));
            }
          },
        ),
      );

      // Report progress.
      onProgress?.call((i + 1) / images.length);
    }

    // Save to a temporary location inside app documents.
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = '${dir.path}/.zenvix_tmp_$timestamp.pdf';
    final file = File(tempPath);
    await file.writeAsBytes(await pdf.save());

    return tempPath;
  }

  /// Map [PdfOptions] to a [PdfPageFormat].
  PdfPageFormat _resolvePageFormat(PdfOptions options) {
    PdfPageFormat base;
    switch (options.pageSize) {
      case PdfPageSize.a4:
        base = PdfPageFormat.a4;
        break;
      case PdfPageSize.letter:
        base = PdfPageFormat.letter;
        break;
    }

    if (options.orientation == PdfOrientation.landscape) {
      base = base.landscape;
    }

    return base;
  }
}
