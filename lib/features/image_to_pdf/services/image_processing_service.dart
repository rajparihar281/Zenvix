import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/editable_image.dart';

/// Handles CPU-intensive image transformations in background isolates
/// via [compute] to avoid blocking the UI thread.
class ImageProcessingService {
  /// Apply all edits defined on [editableImage] and return processed bytes.
  Future<Uint8List> processImage(EditableImage editableImage) async {
    final originalBytes =
        editableImage.processedBytes ??
        await _readFile(editableImage.originalPath);

    return compute(
      _processInIsolate,
      _ProcessParams(
        bytes: originalBytes,
        rotation: editableImage.rotation,
        flipH: editableImage.flipHorizontal,
        flipV: editableImage.flipVertical,
        brightness: editableImage.brightness,
        contrast: editableImage.contrast,
        grayscale: editableImage.grayscale,
      ),
    );
  }

  /// Read original file bytes.
  Future<Uint8List> _readFile(String path) async {
    return File(path).readAsBytes();
  }

  /// Read raw file bytes (public, for use from provider).
  Future<Uint8List> readFileBytes(String path) async {
    return File(path).readAsBytes();
  }

  // ── Isolate entry point ────────────────────────────────────────────────

  static Uint8List _processInIsolate(_ProcessParams params) {
    img.Image? image = img.decodeImage(params.bytes);
    if (image == null) return params.bytes;

    // Rotation
    if (params.rotation != 0) {
      image = img.copyRotate(image, angle: params.rotation);
    }

    // Flip
    if (params.flipH) {
      image = img.flipHorizontal(image);
    }
    if (params.flipV) {
      image = img.flipVertical(image);
    }

    // Brightness (-1.0 to 1.0 → -255 to 255)
    if (params.brightness != 0) {
      final _ = (params.brightness * 255).round();
      image = img.adjustColor(image, brightness: 1.0 + params.brightness);
    }

    // Contrast (-1.0 to 1.0 → scale factor)
    if (params.contrast != 0) {
      image = img.adjustColor(image, contrast: 1.0 + params.contrast);
    }

    // Grayscale
    if (params.grayscale) {
      image = img.grayscale(image);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }
}

/// Parameter bundle for the processing isolate.
class _ProcessParams {
  final Uint8List bytes;
  final double rotation;
  final bool flipH;
  final bool flipV;
  final double brightness;
  final double contrast;
  final bool grayscale;

  const _ProcessParams({
    required this.bytes,
    required this.rotation,
    required this.flipH,
    required this.flipV,
    required this.brightness,
    required this.contrast,
    required this.grayscale,
  });
}
