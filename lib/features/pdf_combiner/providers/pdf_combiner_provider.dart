import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenvix/core/services/storage_provider.dart';
import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/features/pdf_combiner/models/pdf_file_item.dart';
import 'package:zenvix/features/pdf_combiner/services/pdf_combine_service.dart';

enum CombineStatus { idle, processing, done, error }

class PdfCombinerState {
  const PdfCombinerState({
    this.files = const [],
    this.status = CombineStatus.idle,
    this.outputPath,
    this.errorMessage,
  });
  final List<PdfFileItem> files;
  final CombineStatus status;
  final String? outputPath;
  final String? errorMessage;

  PdfCombinerState copyWith({
    List<PdfFileItem>? files,
    CombineStatus? status,
    String? outputPath,
    String? errorMessage,
    bool clearOutput = false,
    bool clearError = false,
  }) =>
      PdfCombinerState(
        files: files ?? this.files,
        status: status ?? this.status,
        outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class PdfCombinerNotifier extends StateNotifier<PdfCombinerState> {
  PdfCombinerNotifier(this._ref) : super(const PdfCombinerState());

  final Ref _ref;
  final PdfCombineService _service = PdfCombineService();

  /// Pick PDF files from the file manager.
  Future<void> pickPdfs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result == null) {
        return;
      }

      final newFiles = result.files
          .where((f) => f.path != null)
          .map(
            (f) => PdfFileItem(
              id: '${DateTime.now().microsecondsSinceEpoch}_${f.name.hashCode}',
              name: f.name,
              path: f.path!,
              sizeBytes: f.size,
            ),
          )
          .toList();

      state = state.copyWith(files: [...state.files, ...newFiles]);
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick PDFs: $e');
    }
  }

  void removeFile(int index) {
    final updated = List<PdfFileItem>.from(state.files)..removeAt(index);
    state = state.copyWith(files: updated);
  }

  void reorderFiles(int oldIndex, int newIndex) {
    final files = List<PdfFileItem>.from(state.files);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = files.removeAt(oldIndex);
    files.insert(targetIndex, item);
    state = state.copyWith(files: files);
  }

  Future<void> mergePdfs() async {
    if (state.files.length < 2) {
      state = state.copyWith(errorMessage: 'Select at least 2 PDFs to merge.');
      return;
    }

    state = state.copyWith(
      status: CombineStatus.processing,
      clearOutput: true,
      clearError: true,
    );

    try {
      final paths = state.files.map((f) => f.path).toList();
      final output = await _service.combinePdfs(paths);
      state = state.copyWith(status: CombineStatus.done, outputPath: output);
    } on Exception catch (e) {
      state = state.copyWith(
        status: CombineStatus.error,
        errorMessage: 'Merge failed: $e',
      );
    }
  }

  /// Save the merged PDF to [directoryPath] with a user-supplied [desiredName].
  ///
  /// Returns the final saved path, or null on failure.
  Future<String?> saveMergedPdfTo({
    required String desiredName,
    required String directoryPath,
    required SaveLocation location,
  }) async {
    if (state.outputPath == null) {
      return null;
    }
    try {
      final storage = _ref.read(storageServiceProvider);
      final fileName = StorageService.ensureExtension(desiredName, '.pdf');
      final result = await storage.copyFile(
        sourcePath: state.outputPath!,
        fileName: fileName,
        directoryPath: directoryPath,
        location: location,
      );
      state = state.copyWith(outputPath: result.savedPath);
      return result.savedPath;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Save failed: $e');
      return null;
    }
  }

  void reset() => state = const PdfCombinerState();
  void clearError() => state = state.copyWith(clearError: true);
}

final pdfCombinerProvider =
    StateNotifierProvider<PdfCombinerNotifier, PdfCombinerState>(
  PdfCombinerNotifier.new,
);
