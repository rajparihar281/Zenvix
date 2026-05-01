import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenvix/core/services/storage_provider.dart';
import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/features/image_to_pdf/models/editable_image.dart';
import 'package:zenvix/features/image_to_pdf/models/pdf_options.dart';
import 'package:zenvix/features/image_to_pdf/services/image_picker_service.dart';
import 'package:zenvix/features/image_to_pdf/services/pdf_generation_service.dart';

// ── State ────────────────────────────────────────────────────────────────

/// The possible states of the conversion pipeline.
enum ConversionStatus { idle, processing, done, error }

/// Immutable state for the Image → PDF feature.
class ImageToPdfState {
  const ImageToPdfState({
    this.images = const [],
    this.pdfOptions = const PdfOptions(),
    this.status = ConversionStatus.idle,
    this.progress = 0,
    this.outputPath,
    this.errorMessage,
  });
  final List<EditableImage> images;
  final PdfOptions pdfOptions;
  final ConversionStatus status;
  final double progress;
  final String? outputPath;
  final String? errorMessage;

  ImageToPdfState copyWith({
    List<EditableImage>? images,
    PdfOptions? pdfOptions,
    ConversionStatus? status,
    double? progress,
    String? outputPath,
    String? errorMessage,
    bool clearOutput = false,
    bool clearError = false,
  }) =>
      ImageToPdfState(
        images: images ?? this.images,
        pdfOptions: pdfOptions ?? this.pdfOptions,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────

class ImageToPdfNotifier extends StateNotifier<ImageToPdfState> {
  ImageToPdfNotifier(this._ref) : super(const ImageToPdfState());

  final Ref _ref;
  final ImagePickerService _pickerService = ImagePickerService();
  final PdfGenerationService _pdfService = PdfGenerationService();

  // ── Image management ─────────────────────────────────────────────────

  /// Add images from gallery.
  Future<void> addFromGallery() async {
    try {
      final paths = await _pickerService.pickFromGallery();
      _addImagePaths(paths);
    } on Exception catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to pick images from gallery: $e',
      );
    }
  }

  /// Add images from file manager.
  Future<void> addFromFileManager() async {
    try {
      final paths = await _pickerService.pickFromFileManager();
      _addImagePaths(paths);
    } on Exception catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to pick images from files: $e',
      );
    }
  }

  /// Add image from camera.
  Future<void> addFromCamera() async {
    try {
      final path = await _pickerService.pickFromCamera();
      if (path != null) {
        _addImagePaths([path]);
      }
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Failed to capture image: $e');
    }
  }

  void _addImagePaths(List<String> paths) {
    if (paths.isEmpty) {
      return;
    }
    final newImages = paths.map((p) {
      final id = '${DateTime.now().microsecondsSinceEpoch}_${p.hashCode}';
      return EditableImage(id: id, originalPath: p);
    }).toList();
    state = state.copyWith(images: [...state.images, ...newImages]);
  }

  /// Remove image at [index].
  void removeImage(int index) {
    final updated = List<EditableImage>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updated);
  }

  /// Reorder image from [oldIndex] to [newIndex].
  void reorderImages(int oldIndex, int newIndex) {
    final images = List<EditableImage>.from(state.images);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = images.removeAt(oldIndex);
    images.insert(targetIndex, item);
    state = state.copyWith(images: images);
  }

  /// Replace image at [index] with an edited version.
  void updateImage(int index, EditableImage edited) {
    final images = List<EditableImage>.from(state.images);
    images[index] = edited;
    state = state.copyWith(images: images);
  }

  // ── PDF options ──────────────────────────────────────────────────────

  void updatePdfOptions(PdfOptions options) {
    state = state.copyWith(pdfOptions: options);
  }

  // ── Conversion ───────────────────────────────────────────────────────

  /// Generate PDF into a temp path (no user prompt yet).
  Future<void> generatePdf() async {
    if (state.images.isEmpty) {
      state = state.copyWith(errorMessage: 'No images selected');
      return;
    }

    state = state.copyWith(
      status: ConversionStatus.processing,
      progress: 0,
      clearOutput: true,
      clearError: true,
    );

    try {
      final tempPath = await _pdfService.generatePdf(
        images: state.images,
        options: state.pdfOptions,
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
      );

      state = state.copyWith(
        status: ConversionStatus.done,
        outputPath: tempPath,
        progress: 1,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: ConversionStatus.error,
        errorMessage: 'PDF generation failed: $e',
      );
    }
  }

  /// Save the generated temp PDF to [directoryPath] with the given [location].
  ///
  /// Returns the final saved path, or null on failure.
  Future<String?> savePdfTo({
    required String directoryPath,
    required SaveLocation location,
  }) async {
    final tempPath = state.outputPath;
    if (tempPath == null) {
      return null;
    }
    try {
      final storage = _ref.read(storageServiceProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = StorageService.ensureExtension(
        'Zenvix_$timestamp',
        '.pdf',
      );

      final result = await storage.copyFile(
        sourcePath: tempPath,
        fileName: fileName,
        directoryPath: directoryPath,
        location: location,
      );

      // Clean up the temp file.
      final tmp = File(tempPath);
      if (tmp.existsSync()) {
        await tmp.delete();
      }

      state = state.copyWith(outputPath: result.savedPath);
      return result.savedPath;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Save failed: $e');
      return null;
    }
  }

  /// Reset for a new conversion.
  void reset() {
    state = const ImageToPdfState();
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────

final imageToPdfProvider =
    StateNotifierProvider<ImageToPdfNotifier, ImageToPdfState>(
  ImageToPdfNotifier.new,
);
