import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/qr_tools/data/services/qr_generator_service.dart';

enum GeneratorStatus { idle, generating, done, error }

class QrGeneratorState {
  const QrGeneratorState({
    this.status = GeneratorStatus.idle,
    this.inputText = '',
    this.foregroundColor = 0xFFFFFFFF,
    this.backgroundColor = 0xFF000000,
    this.pngBytes,
    this.errorMessage,
  });

  final GeneratorStatus status;
  final String inputText;
  final int foregroundColor;
  final int backgroundColor;
  final Uint8List? pngBytes;
  final String? errorMessage;

  /// True when there is valid input to generate from.
  bool get canGenerate => inputText.trim().isNotEmpty;

  QrGeneratorState copyWith({
    GeneratorStatus? status,
    String? inputText,
    int? foregroundColor,
    int? backgroundColor,
    Uint8List? pngBytes,
    String? errorMessage,
    bool clearBytes = false,
    bool clearError = false,
  }) => QrGeneratorState(
    status: status ?? this.status,
    inputText: inputText ?? this.inputText,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    pngBytes: clearBytes ? null : (pngBytes ?? this.pngBytes),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class QrGeneratorNotifier extends StateNotifier<QrGeneratorState> {
  QrGeneratorNotifier() : super(const QrGeneratorState());

  final QrGeneratorService _service = QrGeneratorService();

  void setInput(String text) {
    state = state.copyWith(inputText: text, clearBytes: true, clearError: true);
  }

  void setForegroundColor(Color color) {
    state = state.copyWith(foregroundColor: color.toARGB32(), clearBytes: true);
  }

  void setBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color.toARGB32(), clearBytes: true);
  }

  /// Validates input and captures the QR widget as PNG bytes.
  Future<void> generate(GlobalKey repaintKey) async {
    final error = _service.validate(state.inputText);
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return;
    }

    state = state.copyWith(
      status: GeneratorStatus.generating,
      clearError: true,
      clearBytes: true,
    );

    try {
      final bytes = await _service.captureAsPng(repaintKey);
      state = state.copyWith(status: GeneratorStatus.done, pngBytes: bytes);
    } on Exception catch (e) {
      state = state.copyWith(
        status: GeneratorStatus.error,
        errorMessage: 'Failed to generate QR: $e',
      );
    }
  }

  void reset() => state = const QrGeneratorState();
  void clearError() => state = state.copyWith(clearError: true);
}

final qrGeneratorProvider =
    StateNotifierProvider<QrGeneratorNotifier, QrGeneratorState>(
      (ref) => QrGeneratorNotifier(),
    );
