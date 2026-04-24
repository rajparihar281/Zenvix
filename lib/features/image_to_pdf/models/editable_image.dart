import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Represents a single image with its editing parameters.
///
/// The [processedBytes] field holds the result of applying all edits.
/// It is lazily computed only when the user triggers processing or export.
class EditableImage {
  /// Unique identifier (UUID-style or path-based hash).
  final String id;

  /// Path to the original file on disk.
  final String originalPath;

  /// Bytes after all edits are applied; null if unprocessed.
  Uint8List? processedBytes;

  /// Rotation angle in degrees (0, 90, 180, 270).
  double rotation;

  /// Whether the image is flipped horizontally.
  bool flipHorizontal;

  /// Whether the image is flipped vertically.
  bool flipVertical;

  /// Brightness adjustment (-1.0 to 1.0, 0 = unchanged).
  double brightness;

  /// Contrast adjustment (-1.0 to 1.0, 0 = unchanged).
  double contrast;

  /// Whether to render in grayscale.
  bool grayscale;

  /// Crop rectangle (null = no crop). Normalized 0-1 coordinates.
  Rect? cropRect;

  EditableImage({
    required this.id,
    required this.originalPath,
    this.processedBytes,
    this.rotation = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.brightness = 0,
    this.contrast = 0,
    this.grayscale = false,
    this.cropRect,
  });

  /// Creates a deep copy for immutable state updates.
  EditableImage copyWith({
    String? id,
    String? originalPath,
    Uint8List? processedBytes,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    double? brightness,
    double? contrast,
    bool? grayscale,
    Rect? cropRect,
    bool clearProcessedBytes = false,
    bool clearCropRect = false,
  }) {
    return EditableImage(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      processedBytes:
          clearProcessedBytes ? null : (processedBytes ?? this.processedBytes),
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      grayscale: grayscale ?? this.grayscale,
      cropRect: clearCropRect ? null : (cropRect ?? this.cropRect),
    );
  }

  /// Whether any edits have been applied.
  bool get hasEdits =>
      rotation != 0 ||
      flipHorizontal ||
      flipVertical ||
      brightness != 0 ||
      contrast != 0 ||
      grayscale ||
      cropRect != null;

  /// Resets all editing parameters to defaults.
  EditableImage resetEdits() {
    return copyWith(
      rotation: 0,
      flipHorizontal: false,
      flipVertical: false,
      brightness: 0,
      contrast: 0,
      grayscale: false,
      clearProcessedBytes: true,
      clearCropRect: true,
    );
  }
}
