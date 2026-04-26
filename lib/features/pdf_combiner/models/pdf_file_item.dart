/// Represents a single PDF file selected for merging.
class PdfFileItem {
  const PdfFileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
  });
  final String id;
  final String name;
  final String path;
  final int sizeBytes;

  /// Human-readable file size.
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
