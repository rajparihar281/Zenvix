import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The location the user has chosen to save files.
enum SaveLocation {
  /// `/Documents/Zenvix/` (primary) or app documents directory (fallback).
  defaultZenvix,

  /// A directory chosen by the user via the system picker.
  custom,
}

/// Result of a save operation.
class StorageSaveResult {
  const StorageSaveResult({
    required this.savedPath,
    required this.location,
  });

  /// Absolute path to the saved file.
  final String savedPath;

  /// Which location was ultimately used.
  final SaveLocation location;
}

/// Centralised storage service for Zenvix output files.
///
/// Responsibilities:
/// - Resolve `/Documents/Zenvix/` (with app-dir fallback).
/// - Let the user pick a custom directory.
/// - Persist the user's preference with [SharedPreferences].
/// - Save bytes safely, handling naming conflicts.
class StorageService {
  static const String _prefKey = 'zenvix_custom_save_path';

  // ── Default directory ────────────────────────────────────────────────

  /// Returns the default Zenvix output directory, creating it if needed.
  ///
  /// Priority:
  /// 1. `<Documents>/Zenvix/`
  /// 2. `<ApplicationDocuments>/Zenvix/`
  Future<Directory> getDefaultZenvixDirectory() async {
    Directory? base;

    if (Platform.isAndroid) {
      // Prefer the public Documents folder on Android.
      final publicDocs = Directory('/storage/emulated/0/Documents');
      if (publicDocs.existsSync()) {
        base = publicDocs;
      } else {
        base = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      base = await getApplicationDocumentsDirectory();
    } else {
      // Desktop / other platforms – use application documents.
      base = await getApplicationDocumentsDirectory();
    }

    // Final fallback.
    base ??= await getApplicationDocumentsDirectory();

    final zenvixDir = Directory('${base.path}/Zenvix');
    if (!zenvixDir.existsSync()) {
      await zenvixDir.create(recursive: true);
    }
    return zenvixDir;
  }

  // ── Preference persistence ────────────────────────────────────────────

  /// Returns the persisted custom path, or `null` if none has been set.
  Future<String?> getPersistedCustomPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  /// Persists [path] as the user's preferred custom save location.
  Future<void> persistCustomPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, path);
  }

  /// Clears the persisted custom path (reverts to default).
  Future<void> clearCustomPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  // ── Custom directory picker ───────────────────────────────────────────

  /// Opens a system directory picker and returns the chosen path.
  ///
  /// Returns `null` if the user cancels.
  Future<String?> pickCustomDirectory() async {
    final chosen = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose save location',
    );
    return chosen;
  }

  // ── Save file ─────────────────────────────────────────────────────────

  /// Saves [bytes] as [fileName] into [directoryPath].
  ///
  /// Handles naming conflicts by appending `_1`, `_2`, … before the
  /// extension.  Returns the [StorageSaveResult] with the actual saved path.
  Future<StorageSaveResult> saveBytes({
    required List<int> bytes,
    required String fileName,
    required String directoryPath,
    required SaveLocation location,
  }) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final uniquePath = _resolveUniquePath(directoryPath, fileName);
    final file = File(uniquePath);
    await file.writeAsBytes(bytes, flush: true);

    return StorageSaveResult(savedPath: uniquePath, location: location);
  }

  /// Copies an existing [sourcePath] file into [directoryPath] as [fileName].
  ///
  /// Returns the [StorageSaveResult] with the actual saved path.
  Future<StorageSaveResult> copyFile({
    required String sourcePath,
    required String fileName,
    required String directoryPath,
    required SaveLocation location,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final uniquePath = _resolveUniquePath(directoryPath, fileName);
    await source.copy(uniquePath);

    return StorageSaveResult(savedPath: uniquePath, location: location);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Returns a file path inside [dirPath] that does not yet exist.
  ///
  /// If `name.pdf` exists it tries `name_1.pdf`, `name_2.pdf`, etc.
  String _resolveUniquePath(String dirPath, String fileName) {
    var candidate = '$dirPath/$fileName';
    if (!File(candidate).existsSync()) {
      return candidate;
    }

    // Split name and extension.
    final dotIndex = fileName.lastIndexOf('.');
    final String base;
    final String ext;
    if (dotIndex != -1) {
      base = fileName.substring(0, dotIndex);
      ext = fileName.substring(dotIndex); // includes the dot
    } else {
      base = fileName;
      ext = '';
    }

    var counter = 1;
    do {
      candidate = '$dirPath/${base}_$counter$ext';
      counter++;
    } while (File(candidate).existsSync());

    return candidate;
  }

  /// Ensures [fileName] ends with [extension] (e.g. `'.pdf'`).
  static String ensureExtension(String fileName, String extension) {
    final normalized = extension.startsWith('.') ? extension : '.$extension';
    if (fileName.toLowerCase().endsWith(normalized.toLowerCase())) {
      return fileName;
    }
    return '$fileName$normalized';
  }
}
