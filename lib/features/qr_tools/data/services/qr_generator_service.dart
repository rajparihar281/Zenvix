import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a QR code for `data` to raw PNG bytes.
///
/// The caller is responsible for providing a valid `repaintKey` whose
/// subtree contains a [QrImageView] wrapped in a [RepaintBoundary].
class QrGeneratorService {
  /// Captures the widget tree under [key] as PNG bytes.
  Future<Uint8List> captureAsPng(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Could not find render boundary.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode QR image.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Validates that [input] is non-empty and within QR capacity (~2953 bytes).
  String? validate(String input) {
    if (input.trim().isEmpty) {
      return 'Please enter text or a URL.';
    }
    if (input.length > 2953) {
      return 'Input is too long for a QR code (max 2953 characters).';
    }
    return null;
  }

  /// Returns the appropriate [QrEyeShape] and [QrDataModuleShape] for the
  /// default style used across the app.
  QrImageView buildQrWidget({
    required String data,
    required double size,
    required int foregroundColor,
    required int backgroundColor,
  }) => QrImageView(
    data: data,
    size: size,
    eyeStyle: QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: ui.Color(foregroundColor),
    ),
    dataModuleStyle: QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: ui.Color(foregroundColor),
    ),
    backgroundColor: ui.Color(backgroundColor),
    errorCorrectionLevel: QrErrorCorrectLevel.M,
  );
}
