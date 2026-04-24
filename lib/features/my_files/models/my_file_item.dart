import 'dart:io';

/// Represents a generated file stored by the app.
class MyFileItem {
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modified;
  final String extension;

  const MyFileItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modified,
    required this.extension,
  });

  factory MyFileItem.fromFile(File file) {
    final stat = file.statSync();
    final name = file.path.split('/').last.split('\\').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    return MyFileItem(
      name: name,
      path: file.path,
      sizeBytes: stat.size,
      modified: stat.modified,
      extension: ext,
    );
  }

  /// Human-readable file size.
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  MyFileItem copyWith({
    String? name,
    String? path,
    int? sizeBytes,
    DateTime? modified,
    String? extension,
  }) {
    return MyFileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modified: modified ?? this.modified,
      extension: extension ?? this.extension,
    );
  }
}
