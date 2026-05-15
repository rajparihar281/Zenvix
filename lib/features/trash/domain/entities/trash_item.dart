class TrashItem {

  const TrashItem({
    required this.id,
    required this.originalPath,
    required this.trashedPath,
    required this.fileName,
    required this.sizeBytes,
    required this.deletedAt,
  });
  final String id;
  final String originalPath;
  final String trashedPath;
  final String fileName;
  final int sizeBytes;
  final DateTime deletedAt;

  TrashItem copyWith({
    String? id,
    String? originalPath,
    String? trashedPath,
    String? fileName,
    int? sizeBytes,
    DateTime? deletedAt,
  }) => TrashItem(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      trashedPath: trashedPath ?? this.trashedPath,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      deletedAt: deletedAt ?? this.deletedAt,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
  
    return other is TrashItem &&
      other.id == id &&
      other.originalPath == originalPath &&
      other.trashedPath == trashedPath &&
      other.fileName == fileName &&
      other.sizeBytes == sizeBytes &&
      other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => id.hashCode ^
      originalPath.hashCode ^
      trashedPath.hashCode ^
      fileName.hashCode ^
      sizeBytes.hashCode ^
      deletedAt.hashCode;
}
