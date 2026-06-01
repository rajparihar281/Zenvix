import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Categories of files Zenvix can handle from external intents.
enum IncomingFileCategory {
  /// PDF documents — opened in the built-in PDF viewer.
  pdf,

  /// Word documents (.doc, .docx) — opened in document preview.
  document,

  /// PowerPoint presentations (.ppt, .pptx) — opened in document preview.
  presentation,

  /// Spreadsheets (.xls, .xlsx, .csv) — opened in spreadsheet viewer.
  spreadsheet,

  /// Text / code files (.txt, .json, .xml, .md) — opened in text viewer.
  text,

  /// Unrecognised format — fallback to system opener.
  unsupported,
}

/// Describes a file received via an Android intent.
@immutable
class IncomingFile {
  const IncomingFile({
    required this.path,
    required this.fileName,
    required this.category,
  });

  /// Absolute path to the local copy of the file.
  final String path;

  /// Human-readable file name (extracted from the path).
  final String fileName;

  /// Detected category for routing purposes.
  final IncomingFileCategory category;

  @override
  String toString() =>
      'IncomingFile(name: $fileName, category: $category, path: $path)';
}

/// Centralized service for detecting, classifying, and preparing incoming
/// files from Android intents (ACTION_VIEW / ACTION_SEND).
class IncomingFileService {
  IncomingFileService._();

  static const _platform = MethodChannel('com.Zenvix.Zenvix/incoming_file');

  // ── Extension → category mapping ─────────────────────────────────────

  static const Map<String, IncomingFileCategory> _extensionMap = {
    '.pdf': IncomingFileCategory.pdf,
    '.doc': IncomingFileCategory.document,
    '.docx': IncomingFileCategory.document,
    '.ppt': IncomingFileCategory.presentation,
    '.pptx': IncomingFileCategory.presentation,
    '.xls': IncomingFileCategory.spreadsheet,
    '.xlsx': IncomingFileCategory.spreadsheet,
    '.csv': IncomingFileCategory.spreadsheet,
    '.txt': IncomingFileCategory.text,
    '.json': IncomingFileCategory.text,
    '.xml': IncomingFileCategory.text,
    '.md': IncomingFileCategory.text,
  };

  // ── MIME → category fallback mapping ─────────────────────────────────

  static const Map<String, IncomingFileCategory> _mimeMap = {
    'application/pdf': IncomingFileCategory.pdf,
    'application/msword': IncomingFileCategory.document,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        IncomingFileCategory.document,
    'application/vnd.ms-powerpoint': IncomingFileCategory.presentation,
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        IncomingFileCategory.presentation,
    'application/vnd.ms-excel': IncomingFileCategory.spreadsheet,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        IncomingFileCategory.spreadsheet,
    'text/csv': IncomingFileCategory.spreadsheet,
    'text/plain': IncomingFileCategory.text,
    'application/json': IncomingFileCategory.text,
    'text/xml': IncomingFileCategory.text,
    'application/xml': IncomingFileCategory.text,
    'text/markdown': IncomingFileCategory.text,
  };

  // ── Public API ───────────────────────────────────────────────────────

  /// Resolves a raw URI string (content:// or file://) received from
  /// the ACTION_VIEW MethodChannel into an [IncomingFile].
  static Future<IncomingFile?> resolveFromUri(String rawUri) async {
    try {
      final uri = Uri.parse(rawUri);

      // Ask the native side to copy the content:// URI into our cache.
      String localPath;
      if (uri.scheme == 'content') {
        final result = await _platform.invokeMethod<String>(
          'copyContentUri',
          rawUri,
        );
        if (result == null || result.isEmpty) {
          // Fallback: try to read directly via the URI string as a path.
          localPath = await _copyContentUriViaDart(rawUri);
        } else {
          localPath = result;
        }
      } else {
        // file:// URI — use path directly.
        localPath = uri.toFilePath();
      }

      if (localPath.isEmpty) return null;

      final ext = p.extension(localPath).toLowerCase();
      final category =
          _extensionMap[ext] ?? IncomingFileCategory.unsupported;

      return IncomingFile(
        path: localPath,
        fileName: p.basename(localPath),
        category: category,
      );
    } on Exception catch (e) {
      debugPrint('[IncomingFileService] resolveFromUri failed: $e');
      return null;
    }
  }

  /// Resolves the first usable [IncomingFile] from a list of shared media
  /// files provided by `receive_sharing_intent` (ACTION_SEND path).
  static Future<IncomingFile?> resolveFirstFile(
    List<SharedMediaFile> files,
  ) async {
    for (final file in files) {
      final path = file.path;
      if (path.isEmpty) {
        continue;
      }

      final extension = p.extension(path).toLowerCase();
      final mimeType = file.mimeType?.toLowerCase();

      var category = _extensionMap[extension];
      if (category == null && mimeType != null) {
        category = _mimeMap[mimeType];
      }
      category ??= IncomingFileCategory.unsupported;

      final safePath = await _ensureAccessiblePath(path);
      if (safePath == null) {
        continue;
      }

      return IncomingFile(
        path: safePath,
        fileName: p.basename(safePath),
        category: category,
      );
    }
    return null;
  }

  /// Classifies a single file path by extension.
  static IncomingFileCategory categorizeByPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return _extensionMap[ext] ?? IncomingFileCategory.unsupported;
  }

  /// Classifies by MIME type string.
  static IncomingFileCategory categorizeByMime(String mimeType) =>
      _mimeMap[mimeType.toLowerCase()] ?? IncomingFileCategory.unsupported;

  // ── Private helpers ──────────────────────────────────────────────────

  /// Pure-Dart fallback: reads a content:// URI by opening it as a file
  /// (works when the plugin has already resolved it to a temp path).
  static Future<String> _copyContentUriViaDart(String rawUri) async {
    try {
      final asPath = rawUri.replaceFirst('content://', '/');
      final file = File(asPath);
      if (file.existsSync()) {
        final result = await _ensureAccessiblePath(asPath);
        return result ?? '';
      }
    } on Exception catch (_) {}
    return '';
  }

  /// Copies a file into our app-controlled cache directory so we retain
  /// read access beyond the intent's lifecycle.
  static Future<String?> _ensureAccessiblePath(String originalPath) async {
    try {
      final source = File(originalPath);
      if (!source.existsSync()) {
        debugPrint('[IncomingFileService] Source not found: $originalPath');
        return null;
      }

      final cacheDir = await getTemporaryDirectory();
      if (originalPath.startsWith(cacheDir.path)) {
        return originalPath;
      }

      final incomingDir = Directory(
        p.join(cacheDir.path, 'zenvix_incoming'),
      );
      if (!incomingDir.existsSync()) {
        incomingDir.createSync(recursive: true);
      }

      final destPath = p.join(incomingDir.path, p.basename(originalPath));
      final dest = await source.copy(destPath);

      debugPrint('[IncomingFileService] Copied to: ${dest.path}');
      return dest.path;
    } on Exception catch (e) {
      debugPrint('[IncomingFileService] Copy failed: $e');
      return null;
    }
  }
}
