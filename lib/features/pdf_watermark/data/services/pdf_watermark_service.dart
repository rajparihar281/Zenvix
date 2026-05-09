import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/material.dart' show Color;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/features/pdf_watermark/domain/models/watermark_options.dart';

class PdfWatermarkService {
  PdfWatermarkService({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;

  /// Applies watermark to all pages of [pdfData] and returns the result bytes.
  Future<Uint8List> apply({
    required Uint8List pdfData,
    required WatermarkOptions options,
  }) async {
    final document = PdfDocument(inputBytes: pdfData);
    final pageCount = document.pages.count;

    for (var i = 0; i < pageCount; i++) {
      final page = document.pages[i];
      if (options.type == WatermarkType.text) {
        _applyText(page, options);
      } else {
        await _applyImage(page, options);
      }
    }

    final result = Uint8List.fromList(document.saveSync());
    document.dispose();
    return result;
  }

  void _applyText(PdfPage page, WatermarkOptions options) {
    final size = page.size;
    final font = PdfStandardFont(
      PdfFontFamily.helvetica,
      options.fontSize,
      style: PdfFontStyle.bold,
    );
    final brush = PdfSolidBrush(_toPdfColor(options.color, options.opacity));
    final textSize = font.measureString(options.text);
    final pos = _resolvePosition(
      size,
      textSize.width,
      textSize.height,
      options.position,
    );

    page.graphics
      ..save()
      ..translateTransform(
        pos.dx + textSize.width / 2,
        pos.dy + textSize.height / 2,
      )
      ..rotateTransform(options.rotation)
      ..drawString(
        options.text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(
          -textSize.width / 2,
          -textSize.height / 2,
          textSize.width,
          textSize.height,
        ),
      )
      ..restore();
  }

  Future<void> _applyImage(PdfPage page, WatermarkOptions options) async {
    if (options.imagePath == null) {
      return;
    }
    final imageFile = File(options.imagePath!);
    if (!imageFile.existsSync()) {
      return;
    }

    final imageBytes = await imageFile.readAsBytes();
    final pdfImage = PdfBitmap(imageBytes);
    final size = page.size;
    final imgW = pdfImage.width * options.imageScale;
    final imgH = pdfImage.height * options.imageScale;
    final pos = _resolvePosition(size, imgW, imgH, options.position);

    page.graphics
      ..save()
      ..setTransparency(options.opacity)
      ..translateTransform(pos.dx + imgW / 2, pos.dy + imgH / 2)
      ..rotateTransform(options.rotation)
      ..drawImage(
        pdfImage,
        Rect.fromLTWH(-imgW / 2, -imgH / 2, imgW, imgH),
      )
      ..restore();
  }

  Offset _resolvePosition(
    Size pageSize,
    double w,
    double h,
    WatermarkPosition position,
  ) {
    final pw = pageSize.width;
    final ph = pageSize.height;
    const margin = 24.0;

    return switch (position) {
      WatermarkPosition.center => Offset((pw - w) / 2, (ph - h) / 2),
      WatermarkPosition.topLeft => const Offset(margin, margin),
      WatermarkPosition.topRight => Offset(pw - w - margin, margin),
      WatermarkPosition.bottomLeft => Offset(margin, ph - h - margin),
      WatermarkPosition.bottomRight =>
        Offset(pw - w - margin, ph - h - margin),
    };
  }

  /// Saves watermarked bytes to the Zenvix folder.
  Future<String> saveToDevice(Uint8List data, String desiredName) async {
    var name = desiredName;
    if (!name.toLowerCase().endsWith('.pdf')) {
      name = '$name.pdf';
    }
    final dir = await _storage.getDefaultZenvixDirectory();
    final result = await _storage.saveBytes(
      bytes: data,
      fileName: name,
      directoryPath: dir.path,
      location: SaveLocation.defaultZenvix,
    );
    return result.savedPath;
  }

  PdfColor _toPdfColor(Color color, double opacity) => PdfColor(
    (color.r * 255.0).round().clamp(0, 255),
    (color.g * 255.0).round().clamp(0, 255),
    (color.b * 255.0).round().clamp(0, 255),
    (opacity * 255).round(),
  );
}
