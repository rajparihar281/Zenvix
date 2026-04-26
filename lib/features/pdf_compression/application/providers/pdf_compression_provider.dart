import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/pdf_compression/data/services/pdf_compression_service.dart';
import 'package:zenvix/features/pdf_compression/domain/models/compression_options.dart';

// ── Status ───────────────────────────────────────────────────────────────

enum CompressionStatus { idle, loading, compressing, done, error }

// ── State ────────────────────────────────────────────────────────────────

class PdfCompressionState {
  const PdfCompressionState({
    this.status = CompressionStatus.idle,
    this.level = CompressionLevel.medium,
    this.progress = 0,
    this.originalFileName,
    this.originalSize = 0,
    this.estimatedSize = 0,
    this.compressedSize = 0,
    this.pdfData,
    this.compressedData,
    this.outputPath,
    this.errorMessage,
  });

  final CompressionStatus status;
  final CompressionLevel level;
  final double progress;
  final String? originalFileName;
  final int originalSize;
  final int estimatedSize;
  final int compressedSize;
  final Uint8List? pdfData;
  final Uint8List? compressedData;
  final String? outputPath;
  final String? errorMessage;

  PdfCompressionState copyWith({
    CompressionStatus? status,
    CompressionLevel? level,
    double? progress,
    String? originalFileName,
    int? originalSize,
    int? estimatedSize,
    int? compressedSize,
    Uint8List? pdfData,
    Uint8List? compressedData,
    String? outputPath,
    String? errorMessage,
    bool clearOutput = false,
    bool clearError = false,
    bool clearCompressed = false,
  }) => PdfCompressionState(
    status: status ?? this.status,
    level: level ?? this.level,
    progress: progress ?? this.progress,
    originalFileName: originalFileName ?? this.originalFileName,
    originalSize: originalSize ?? this.originalSize,
    estimatedSize: estimatedSize ?? this.estimatedSize,
    compressedSize: compressedSize ?? this.compressedSize,
    pdfData: pdfData ?? this.pdfData,
    compressedData: clearCompressed
        ? null
        : (compressedData ?? this.compressedData),
    outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  /// Human-readable formatted size.
  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────

class PdfCompressionNotifier extends StateNotifier<PdfCompressionState> {
  PdfCompressionNotifier() : super(const PdfCompressionState());

  final PdfCompressionService _service = PdfCompressionService();

  /// Pick a single PDF file for compression.
  Future<void> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        return;
      }

      state = state.copyWith(
        status: CompressionStatus.loading,
        clearError: true,
        clearOutput: true,
        clearCompressed: true,
      );

      final fileData = await File(file.path!).readAsBytes();
      final estimated = _service.estimateCompressedSize(
        originalSize: fileData.length,
        level: state.level,
      );

      state = state.copyWith(
        status: CompressionStatus.idle,
        originalFileName: file.name,
        originalSize: fileData.length,
        estimatedSize: estimated,
        pdfData: fileData,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: CompressionStatus.error,
        errorMessage: 'Failed to load PDF: $e',
      );
    }
  }

  /// Update the selected compression level and recalculate estimated size.
  void setLevel(CompressionLevel level) {
    final estimated = _service.estimateCompressedSize(
      originalSize: state.originalSize,
      level: level,
    );
    state = state.copyWith(
      level: level,
      estimatedSize: estimated,
      clearCompressed: true,
      clearOutput: true,
    );
  }

  /// Run the compression pipeline.
  Future<void> compress() async {
    if (state.pdfData == null) {
      state = state.copyWith(errorMessage: 'No PDF loaded.');
      return;
    }

    state = state.copyWith(
      status: CompressionStatus.compressing,
      progress: 0,
      clearError: true,
      clearOutput: true,
    );

    try {
      final compressed = await _service.compress(
        pdfData: state.pdfData!,
        level: state.level,
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
      );

      state = state.copyWith(
        status: CompressionStatus.done,
        compressedData: compressed,
        compressedSize: compressed.length,
        progress: 1,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: CompressionStatus.error,
        errorMessage: 'Compression failed: $e',
      );
    }
  }

  /// Save the compressed PDF to the device.
  Future<String?> saveCompressedPdf(String desiredName) async {
    if (state.compressedData == null) {
      return null;
    }
    try {
      final path = await _service.saveToDevice(
        state.compressedData!,
        desiredName,
      );
      state = state.copyWith(outputPath: path);
      return path;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Save failed: $e');
      return null;
    }
  }

  void reset() => state = const PdfCompressionState();
  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ─────────────────────────────────────────────────────────────

final pdfCompressionProvider =
    StateNotifierProvider<PdfCompressionNotifier, PdfCompressionState>(
      (ref) => PdfCompressionNotifier(),
    );
