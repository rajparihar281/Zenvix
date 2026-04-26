import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/pdf_page_manager/models/pdf_page_item.dart';
import 'package:zenvix/features/pdf_page_manager/services/pdf_page_manager_service.dart';

enum PageManagerStatus { idle, loading, processing, done, error }

class PdfPageManagerState {
  // For multi-select actions

  const PdfPageManagerState({
    this.originalPdfPath,
    this.originalPdfName,
    this.originalPdfData,
    this.pages = const [],
    this.status = PageManagerStatus.idle,
    this.outputPath,
    this.errorMessage,
    this.selectedPageIds = const {},
  });
  final String? originalPdfPath;
  final String? originalPdfName;
  final Uint8List? originalPdfData;
  final List<PdfPageItem> pages;
  final PageManagerStatus status;
  final String? outputPath;
  final String? errorMessage;
  final Set<String> selectedPageIds;

  PdfPageManagerState copyWith({
    String? originalPdfPath,
    String? originalPdfName,
    Uint8List? originalPdfData,
    List<PdfPageItem>? pages,
    PageManagerStatus? status,
    String? outputPath,
    String? errorMessage,
    Set<String>? selectedPageIds,
    bool clearOutput = false,
    bool clearError = false,
  }) => PdfPageManagerState(
    originalPdfPath: originalPdfPath ?? this.originalPdfPath,
    originalPdfName: originalPdfName ?? this.originalPdfName,
    originalPdfData: originalPdfData ?? this.originalPdfData,
    pages: pages ?? this.pages,
    status: status ?? this.status,
    outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    selectedPageIds: selectedPageIds ?? this.selectedPageIds,
  );
}

class PdfPageManagerNotifier extends StateNotifier<PdfPageManagerState> {
  PdfPageManagerNotifier() : super(const PdfPageManagerState());
  final PdfPageManagerService _service = PdfPageManagerService();

  /// Pick a PDF file to manage
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
        status: PageManagerStatus.loading,
        originalPdfPath: file.path,
        originalPdfName: file.name,
        clearError: true,
        clearOutput: true,
      );

      final fileData = await File(file.path!).readAsBytes();

      final pages = await _service.getPdfPages(fileData);

      state = state.copyWith(
        status: PageManagerStatus.idle,
        originalPdfData: fileData,
        pages: pages,
        selectedPageIds: {}, // reset selection
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: PageManagerStatus.error,
        errorMessage: 'Failed to load PDF: $e',
      );
    }
  }

  void reorderPages(int oldIndex, int newIndex) {
    final pages = List<PdfPageItem>.from(state.pages);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = pages.removeAt(oldIndex);
    pages.insert(targetIndex, item);
    state = state.copyWith(pages: pages);
  }

  void rotatePage(String id) {
    final pages = state.pages.map((p) {
      if (p.id == id) {
        return p.copyWith(rotationAngle: (p.rotationAngle + 90) % 360);
      }
      return p;
    }).toList();
    state = state.copyWith(pages: pages);
  }

  void rotateSelectedPages() {
    final pages = state.pages.map((p) {
      if (state.selectedPageIds.contains(p.id)) {
        return p.copyWith(rotationAngle: (p.rotationAngle + 90) % 360);
      }
      return p;
    }).toList();
    state = state.copyWith(pages: pages);
  }

  void deletePage(String id) {
    final pages = state.pages.where((p) => p.id != id).toList();
    final selected = Set<String>.from(state.selectedPageIds)..remove(id);
    state = state.copyWith(pages: pages, selectedPageIds: selected);
  }

  void deleteSelectedPages() {
    final pages = state.pages
        .where((p) => !state.selectedPageIds.contains(p.id))
        .toList();
    state = state.copyWith(pages: pages, selectedPageIds: {});
  }

  void togglePageSelection(String id) {
    final selected = Set<String>.from(state.selectedPageIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedPageIds: selected);
  }

  void toggleSelectAll() {
    if (state.selectedPageIds.length == state.pages.length) {
      state = state.copyWith(selectedPageIds: {});
    } else {
      final allIds = state.pages.map((p) => p.id).toSet();
      state = state.copyWith(selectedPageIds: allIds);
    }
  }

  Future<void> savePdf(String desiredName) async {
    if (state.pages.isEmpty) {
      state = state.copyWith(errorMessage: 'No pages to save.');
      return;
    }

    if (state.originalPdfData == null) {
      state = state.copyWith(errorMessage: 'Original PDF data missing.');
      return;
    }

    // If there are selected pages, extract only those. Otherwise save all pages in current order.
    final pagesToSave = state.selectedPageIds.isNotEmpty
        ? state.pages
              .where((p) => state.selectedPageIds.contains(p.id))
              .toList()
        : state.pages;

    state = state.copyWith(
      status: PageManagerStatus.processing,
      clearError: true,
      clearOutput: true,
    );

    try {
      final outputPath = await _service.exportPdf(
        originalPdfData: state.originalPdfData!,
        finalPages: pagesToSave,
        desiredName: desiredName,
      );

      state = state.copyWith(
        status: PageManagerStatus.done,
        outputPath: outputPath,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: PageManagerStatus.error,
        errorMessage: 'Failed to export PDF: $e',
      );
    }
  }

  void reset() => state = const PdfPageManagerState();
  void clearError() => state = state.copyWith(clearError: true);
}

final pdfPageManagerProvider =
    StateNotifierProvider<PdfPageManagerNotifier, PdfPageManagerState>(
      (ref) => PdfPageManagerNotifier(),
    );
