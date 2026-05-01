import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenvix/core/services/storage_service.dart';

// ── Singleton provider ────────────────────────────────────────────────────────

/// Provides a single [StorageService] instance across the app.
final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);

// ── Preference state ──────────────────────────────────────────────────────────

/// Immutable state for the user's storage preference.
class StoragePreferenceState {
  const StoragePreferenceState({
    this.customPath,
    this.alwaysUseCustom = false,
    this.isLoaded = false,
  });

  /// The last custom path chosen by the user (may be null).
  final String? customPath;

  /// Whether the user always wants to save to [customPath].
  final bool alwaysUseCustom;

  /// True once the state has been hydrated from `[SharedPreferences]`.
  final bool isLoaded;

  StoragePreferenceState copyWith({
    String? customPath,
    bool? alwaysUseCustom,
    bool? isLoaded,
    bool clearCustomPath = false,
  }) =>
      StoragePreferenceState(
        customPath:
            clearCustomPath ? null : (customPath ?? this.customPath),
        alwaysUseCustom: alwaysUseCustom ?? this.alwaysUseCustom,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages and persists the user's preferred save-location choice.
class StoragePreferenceNotifier
    extends StateNotifier<StoragePreferenceState> {
  StoragePreferenceNotifier(this._storage)
      : super(const StoragePreferenceState()) {
    _hydrate();
  }

  final StorageService _storage;

  /// Load the persisted custom path from `[SharedPreferences]`.
  Future<void> _hydrate() async {
    final saved = await _storage.getPersistedCustomPath();
    state = state.copyWith(
      customPath: saved,
      alwaysUseCustom: saved != null,
      isLoaded: true,
    );
  }

  /// Set a new custom path and persist it.
  Future<void> setCustomPath(String path) async {
    await _storage.persistCustomPath(path);
    state = state.copyWith(
      customPath: path,
      alwaysUseCustom: true,
    );
  }

  /// Toggle the "always use custom location" flag.
  ///
  /// Disabling it clears the persisted path.
  Future<void> setAlwaysUseCustom({required bool value}) async {
    if (!value) {
      await _storage.clearCustomPath();
      state = state.copyWith(
        alwaysUseCustom: false,
        clearCustomPath: true,
      );
    } else {
      state = state.copyWith(alwaysUseCustom: true);
    }
  }

  /// Clear everything and revert to the default Zenvix folder.
  Future<void> resetToDefault() async {
    await _storage.clearCustomPath();
    state = state.copyWith(
      alwaysUseCustom: false,
      clearCustomPath: true,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final storagePreferenceProvider = StateNotifierProvider<
    StoragePreferenceNotifier, StoragePreferenceState>(
  (ref) => StoragePreferenceNotifier(ref.watch(storageServiceProvider)),
);
