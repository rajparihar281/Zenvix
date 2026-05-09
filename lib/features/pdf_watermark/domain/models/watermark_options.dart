import 'package:flutter/material.dart';

enum WatermarkType { text, image }

enum WatermarkPosition {
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  String get label => switch (this) {
    WatermarkPosition.center => 'Center',
    WatermarkPosition.topLeft => 'Top Left',
    WatermarkPosition.topRight => 'Top Right',
    WatermarkPosition.bottomLeft => 'Bottom Left',
    WatermarkPosition.bottomRight => 'Bottom Right',
  };
}

class WatermarkOptions {
  const WatermarkOptions({
    this.type = WatermarkType.text,
    this.text = 'CONFIDENTIAL',
    this.fontSize = 48.0,
    this.opacity = 0.3,
    this.rotation = -45.0,
    this.color = Colors.white,
    this.position = WatermarkPosition.center,
    this.imageScale = 0.3,
    this.imagePath,
  });

  final WatermarkType type;
  final String text;
  final double fontSize;
  final double opacity;
  final double rotation;
  final Color color;
  final WatermarkPosition position;
  final double imageScale;
  final String? imagePath;

  WatermarkOptions copyWith({
    WatermarkType? type,
    String? text,
    double? fontSize,
    double? opacity,
    double? rotation,
    Color? color,
    WatermarkPosition? position,
    double? imageScale,
    String? imagePath,
    bool clearImagePath = false,
  }) => WatermarkOptions(
    type: type ?? this.type,
    text: text ?? this.text,
    fontSize: fontSize ?? this.fontSize,
    opacity: opacity ?? this.opacity,
    rotation: rotation ?? this.rotation,
    color: color ?? this.color,
    position: position ?? this.position,
    imageScale: imageScale ?? this.imageScale,
    imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
  );
}
