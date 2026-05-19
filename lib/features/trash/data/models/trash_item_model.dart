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

  factory TrashItemModel.fromEntity(TrashItem entity) => TrashItemModel(
    id: entity.id,
    originalPath: entity.originalPath,
    trashedPath: entity.trashedPath,
    fileName: entity.fileName,
    sizeBytes: entity.sizeBytes,
    deletedAt: entity.deletedAt,
  );

  factory TrashItemModel.fromMap(Map<String, dynamic> map) => TrashItemModel(
    id: map['id'] as String? ?? '',
    originalPath: map['originalPath'] as String? ?? '',
    trashedPath: map['trashedPath'] as String? ?? '',
    fileName: map['fileName'] as String? ?? '',
    sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    deletedAt: DateTime.parse(map['deletedAt'] as String),
  );

  factory TrashItemModel.fromJson(String source) =>
      TrashItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
    'id': id,
    'originalPath': originalPath,
    'trashedPath': trashedPath,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'deletedAt': deletedAt.toIso8601String(),
  };

  String toJson() => json.encode(toMap());
}
