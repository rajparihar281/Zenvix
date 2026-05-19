import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenvix/features/trash/data/datasources/trash_local_data_source.dart';
import 'package:zenvix/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:zenvix/features/trash/domain/entities/trash_item.dart';
import 'package:zenvix/features/trash/domain/repositories/trash_repository.dart';
import 'package:zenvix/features/trash/services/trash_file_service.dart';

// --- State ---

class TrashState {
  const TrashState({
    this.items = const [],
    this.selectedItems = const {},
    this.isLoading = true,
    this.searchQuery = '',
    this.errorMessage,
  });

  final List<TrashItem> items;
  final Set<String> selectedItems;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  bool get isSelectionMode => selectedItems.isNotEmpty;

  List<TrashItem> get filteredItems {
    if (searchQuery.isEmpty) {
      return items;
    }
    final lowerQuery = searchQuery.toLowerCase();
    return items
        .where((item) => item.fileName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  TrashState copyWith({
    List<TrashItem>? items,
    Set<String>? selectedItems,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) => TrashState(
    items: items ?? this.items,
    selectedItems: selectedItems ?? this.selectedItems,
    isLoading: isLoading ?? this.isLoading,
    searchQuery: searchQuery ?? this.searchQuery,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

// --- Notifier ---

class TrashNotifier extends StateNotifier<TrashState> {
  TrashNotifier() : super(const TrashState()) {
    _init();
  }

  TrashRepository? _repository;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = TrashLocalDataSourceImpl(prefs);
      final fileService = TrashFileService();
      _repository = TrashRepositoryImpl(localDataSource, fileService);

      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize trash: $e',
      );
    }
  }

  Future<void> loadItems() async {
    if (_repository == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository!.getTrashItems();
      // Sort newest deleted first
      items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      state = state.copyWith(items: items, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load trash items: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSelection(String id) {
    final newSelection = Set<String>.from(state.selectedItems);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }
    state = state.copyWith(selectedItems: newSelection);
  }

  void clearSelection() {
    state = state.copyWith(selectedItems: const {});
  }

  void selectAll() {
    final allIds = state.filteredItems.map((e) => e.id).toSet();
    state = state.copyWith(selectedItems: allIds);
  }

  Future<void> restoreSelected() async {
    if (_repository == null || state.selectedItems.isEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final itemsToRestore = state.items
          .where((item) => state.selectedItems.contains(item.id))
          .toList();
      for (final item in itemsToRestore) {
        await _repository!.restoreItem(item);
      }

      clearSelection();
      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore items: $e',
      );
    }
  }

  Future<void> deleteSelected() async {
    if (_repository == null || state.selectedItems.isEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final itemsToDelete = state.items
          .where((item) => state.selectedItems.contains(item.id))
          .toList();
      for (final item in itemsToDelete) {
        await _repository!.permanentlyDeleteItem(item);
      }

      clearSelection();
      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete items: $e',
      );
    }
  }

  Future<void> emptyTrash() async {
    if (_repository == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository!.emptyTrash();
      clearSelection();
      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to empty trash: $e',
      );
    }
  }

  Future<void> restoreItem(TrashItem item) async {
    if (_repository == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository!.restoreItem(item);
      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore item: $e',
      );
    }
  }

  Future<void> permanentlyDeleteItem(TrashItem item) async {
    if (_repository == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository!.permanentlyDeleteItem(item);
      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete item: $e',
      );
    }
  }

  Future<void> moveToTrash(String originalPath) async {
    if (_repository == null) {
      // If not initialized yet, initialize it
      await _init();
    }
    if (_repository == null) {
      return;
    }

    try {
      await _repository!.moveToTrash(originalPath);
      await loadItems();
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Failed to move to trash: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// --- Provider ---

final trashProvider = StateNotifierProvider<TrashNotifier, TrashState>(
  (ref) => TrashNotifier(),
);
