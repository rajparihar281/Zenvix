  import 'dart:convert';

import 'package:zenvix/features/trash/domain/entities/trash_item.dart';

class TrashItemModel extends TrashItem {
  const TrashItemModel({
    required super.id,
    required super.originalPath,
    required super.trashedPath,
    required super.fileName,
    required super.sizeBytes,
    required super.deletedAt,
  });

  factory TrashItemModel.fromEntity(TrashItem entity) {
    return TrashItemModel(
      id: entity.id,
      originalPath: entity.originalPath,
      trashedPath: entity.trashedPath,
      fileName: entity.fileName,
      sizeBytes: entity.sizeBytes,
      deletedAt: entity.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalPath': originalPath,
      'trashedPath': trashedPath,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory TrashItemModel.fromMap(Map<String, dynamic> map) {
    return TrashItemModel(
      id: map['id'] ?? '',
      originalPath: map['originalPath'] ?? '',
      trashedPath: map['trashedPath'] ?? '',
      fileName: map['fileName'] ?? '',
      sizeBytes: map['sizeBytes']?.toInt() ?? 0,
      deletedAt: DateTime.parse(map['deletedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory TrashItemModel.fromJson(String source) =>
      TrashItemModel.fromMap(json.decode(source));
}
