import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/my_file_item.dart';
import '../services/my_files_service.dart';

enum FileSortOption { newest, oldest, nameAsc, nameDesc, sizeDesc, sizeAsc }

class MyFilesState {
  final List<MyFileItem> files;
  final bool isLoading;
  final String? errorMessage;
  final FileSortOption sortOption;

  const MyFilesState({
    this.files = const [],
    this.isLoading = false,
    this.errorMessage,
    this.sortOption = FileSortOption.newest,
  });

  MyFilesState copyWith({
    List<MyFileItem>? files,
    bool? isLoading,
    String? errorMessage,
    FileSortOption? sortOption,
    bool clearError = false,
  }) {
    return MyFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class MyFilesNotifier extends StateNotifier<MyFilesState> {
  final MyFilesService _service = MyFilesService();

  MyFilesNotifier() : super(const MyFilesState()) {
    loadFiles();
  }

  Future<void> loadFiles() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final files = await _service.getGeneratedFiles();
      state = state.copyWith(
        isLoading: false,
        files: _sortFiles(files, state.sortOption),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load files: $e',
      );
    }
  }

  void setSortOption(FileSortOption option) {
    if (state.sortOption == option) return;
    state = state.copyWith(
      sortOption: option,
      files: _sortFiles(state.files, option),
    );
  }

  List<MyFileItem> _sortFiles(List<MyFileItem> files, FileSortOption option) {
    final sorted = List<MyFileItem>.from(files);
    switch (option) {
      case FileSortOption.newest:
        sorted.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case FileSortOption.oldest:
        sorted.sort((a, b) => a.modified.compareTo(b.modified));
        break;
      case FileSortOption.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case FileSortOption.nameDesc:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case FileSortOption.sizeDesc:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case FileSortOption.sizeAsc:
        sorted.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        break;
    }
    return sorted;
  }

  Future<void> deleteFile(String path) async {
    try {
      await _service.deleteFile(path);
      // Remove from state
      final updated = state.files.where((f) => f.path != path).toList();
      state = state.copyWith(files: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete file: $e');
    }
  }

  Future<void> renameFile(String oldPath, String newName) async {
    try {
      final updatedItem = await _service.renameFile(oldPath, newName);
      final updatedFiles = state.files.map((f) {
        return f.path == oldPath ? updatedItem : f;
      }).toList();
      state = state.copyWith(files: _sortFiles(updatedFiles, state.sortOption));
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename file: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final myFilesProvider = StateNotifierProvider<MyFilesNotifier, MyFilesState>(
  (ref) => MyFilesNotifier(),
);
