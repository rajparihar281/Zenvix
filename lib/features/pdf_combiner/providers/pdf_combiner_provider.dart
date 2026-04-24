import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pdf_file_item.dart';
import '../services/pdf_combine_service.dart';

enum CombineStatus { idle, processing, done, error }

class PdfCombinerState {
  final List<PdfFileItem> files;
  final CombineStatus status;
  final String? outputPath;
  final String? errorMessage;

  const PdfCombinerState({
    this.files = const [],
    this.status = CombineStatus.idle,
    this.outputPath,
    this.errorMessage,
  });

  PdfCombinerState copyWith({
    List<PdfFileItem>? files,
    CombineStatus? status,
    String? outputPath,
    String? errorMessage,
    bool clearOutput = false,
    bool clearError = false,
  }) {
    return PdfCombinerState(
      files: files ?? this.files,
      status: status ?? this.status,
      outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PdfCombinerNotifier extends StateNotifier<PdfCombinerState> {
  final PdfCombineService _service = PdfCombineService();
  PdfCombinerNotifier() : super(const PdfCombinerState());

  /// Pick PDF files from the file manager.
  Future<void> pickPdfs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result == null) return;

      final newFiles = result.files.where((f) => f.path != null).map((f) {
        return PdfFileItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${f.name.hashCode}',
          name: f.name,
          path: f.path!,
          sizeBytes: f.size,
        );
      }).toList();

      state = state.copyWith(files: [...state.files, ...newFiles]);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick PDFs: $e');
    }
  }

  void removeFile(int index) {
    final updated = List<PdfFileItem>.from(state.files)..removeAt(index);
    state = state.copyWith(files: updated);
  }

  void reorderFiles(int oldIndex, int newIndex) {
    final files = List<PdfFileItem>.from(state.files);
    if (newIndex > oldIndex) newIndex--;
    final item = files.removeAt(oldIndex);
    files.insert(newIndex, item);
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
    } catch (e) {
      state = state.copyWith(
        status: CombineStatus.error,
        errorMessage: 'Merge failed: $e',
      );
    }
  }

  Future<String?> saveMergedPdf(String desiredName) async {
    if (state.outputPath == null) return null;
    try {
      return await _service.saveToDevice(state.outputPath!, desiredName);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Save failed: $e');
      return null;
    }
  }

  void reset() => state = const PdfCombinerState();
  void clearError() => state = state.copyWith(clearError: true);
}

final pdfCombinerProvider =
    StateNotifierProvider<PdfCombinerNotifier, PdfCombinerState>(
      (ref) => PdfCombinerNotifier(),
    );
