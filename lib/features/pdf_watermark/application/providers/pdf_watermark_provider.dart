import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zenvix/features/pdf_watermark/data/services/pdf_watermark_service.dart';
import 'package:zenvix/features/pdf_watermark/domain/models/watermark_options.dart';

enum WatermarkStatus { idle, loading, processing, done, error }

class PdfWatermarkState {
  const PdfWatermarkState({
    this.status = WatermarkStatus.idle,
    this.options = const WatermarkOptions(),
    this.originalFileName,
    this.pdfData,
    this.watermarkedData,
    this.outputPath,
    this.errorMessage,
  });

  final WatermarkStatus status;
  final WatermarkOptions options;
  final String? originalFileName;
  final Uint8List? pdfData;
  final Uint8List? watermarkedData;
  final String? outputPath;
  final String? errorMessage;

  PdfWatermarkState copyWith({
    WatermarkStatus? status,
    WatermarkOptions? options,
    String? originalFileName,
    Uint8List? pdfData,
    Uint8List? watermarkedData,
    String? outputPath,
    String? errorMessage,
    bool clearError = false,
    bool clearOutput = false,
    bool clearWatermarked = false,
  }) => PdfWatermarkState(
    status: status ?? this.status,
    options: options ?? this.options,
    originalFileName: originalFileName ?? this.originalFileName,
    pdfData: pdfData ?? this.pdfData,
    watermarkedData: clearWatermarked
        ? null
        : (watermarkedData ?? this.watermarkedData),
    outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class PdfWatermarkNotifier extends StateNotifier<PdfWatermarkState> {
  PdfWatermarkNotifier() : super(const PdfWatermarkState());

  final PdfWatermarkService _service = PdfWatermarkService();
  final ImagePicker _imagePicker = ImagePicker();

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
        status: WatermarkStatus.loading,
        clearError: true,
        clearOutput: true,
        clearWatermarked: true,
      );

      final bytes = await File(file.path!).readAsBytes();

      // Validate PDF.
      try {
        PdfDocument(inputBytes: bytes).dispose();
      } on Exception {
        state = state.copyWith(
          status: WatermarkStatus.error,
          errorMessage: 'Invalid or corrupted PDF file.',
        );
        return;
      }

      state = state.copyWith(
        status: WatermarkStatus.idle,
        originalFileName: file.name,
        pdfData: bytes,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: WatermarkStatus.error,
        errorMessage: 'Failed to load PDF: $e',
      );
    }
  }

  Future<void> pickWatermarkImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) {
        return;
      }
      state = state.copyWith(
        options: state.options.copyWith(
          type: WatermarkType.image,
          imagePath: picked.path,
        ),
        clearWatermarked: true,
      );
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick image: $e');
    }
  }

  void updateOptions(WatermarkOptions options) {
    state = state.copyWith(options: options, clearWatermarked: true);
  }

  Future<void> applyWatermark() async {
    if (state.pdfData == null) {
      state = state.copyWith(errorMessage: 'No PDF loaded.');
      return;
    }
    if (state.options.type == WatermarkType.text &&
        state.options.text.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Watermark text cannot be empty.');
      return;
    }
    if (state.options.type == WatermarkType.image &&
        state.options.imagePath == null) {
      state = state.copyWith(errorMessage: 'No watermark image selected.');
      return;
    }

    state = state.copyWith(
      status: WatermarkStatus.processing,
      clearError: true,
      clearOutput: true,
      clearWatermarked: true,
    );

    try {
      final result = await _service.apply(
        pdfData: state.pdfData!,
        options: state.options,
      );
      state = state.copyWith(
        status: WatermarkStatus.done,
        watermarkedData: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: WatermarkStatus.error,
        errorMessage: 'Failed to apply watermark: $e',
      );
    }
  }

  Future<String?> saveToDevice(String desiredName) async {
    if (state.watermarkedData == null) {
      return null;
    }
    try {
      final path = await _service.saveToDevice(
        state.watermarkedData!,
        desiredName,
      );
      state = state.copyWith(outputPath: path);
      return path;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Save failed: $e');
      return null;
    }
  }

  void reset() => state = const PdfWatermarkState();
  void clearError() => state = state.copyWith(clearError: true);
}

final pdfWatermarkProvider =
    StateNotifierProvider<PdfWatermarkNotifier, PdfWatermarkState>(
      (ref) => PdfWatermarkNotifier(),
    );
