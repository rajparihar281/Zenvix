import 'dart:typed_data';

class PdfPageItem {
  const PdfPageItem({
    required this.id,
    required this.originalIndex,
    required this.thumbnailData,
    this.rotationAngle = 0,
    this.isSelected = false,
  });
  final String id;
  final int originalIndex; // The 0-based index in the original PDF
  final Uint8List thumbnailData;
  final int rotationAngle; // 0, 90, 180, 270
  final bool isSelected;

  PdfPageItem copyWith({
    String? id,
    int? originalIndex,
    Uint8List? thumbnailData,
    int? rotationAngle,
    bool? isSelected,
  }) => PdfPageItem(
    id: id ?? this.id,
    originalIndex: originalIndex ?? this.originalIndex,
    thumbnailData: thumbnailData ?? this.thumbnailData,
    rotationAngle: rotationAngle ?? this.rotationAngle,
    isSelected: isSelected ?? this.isSelected,
  );
}
