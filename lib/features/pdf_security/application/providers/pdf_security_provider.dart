import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/pdf_security/data/services/pdf_security_service.dart';
import 'package:zenvix/features/pdf_security/domain/models/security_options.dart';

// ── Status ───────────────────────────────────────────────────────────────

enum SecurityStatus { idle, loading, processing, done, error }

// ── State ────────────────────────────────────────────────────────────────

class PdfSecurityState {
  const PdfSecurityState({
    this.status = SecurityStatus.idle,
    this.mode = SecurityMode.protect,
    this.permissions = const SecurityPermissions(),
    this.originalFileName,
    this.originalSize = 0,
    this.pdfData,
    this.processedData,
    this.outputPath,
    this.errorMessage,
  });

  final SecurityStatus status;
  final SecurityMode mode;
  final SecurityPermissions permissions;
  final String? originalFileName;
  final int originalSize;
  final Uint8List? pdfData;
  final Uint8List? processedData;
  final String? outputPath;
  final String? errorMessage;

  PdfSecurityState copyWith({
    SecurityStatus? status,
    SecurityMode? mode,
    SecurityPermissions? permissions,
    String? originalFileName,
    int? originalSize,
    Uint8List? pdfData,
    Uint8List? processedData,
    String? outputPath,
    String? errorMessage,
    bool clearOutput = false,
    bool clearError = false,
    bool clearProcessed = false,
  }) => PdfSecurityState(
    status: status ?? this.status,
    mode: mode ?? this.mode,
    permissions: permissions ?? this.permissions,
    originalFileName: originalFileName ?? this.originalFileName,
    originalSize: originalSize ?? this.originalSize,
    pdfData: pdfData ?? this.pdfData,
    processedData: clearProcessed
        ? null
        : (processedData ?? this.processedData),
    outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  /// Human-readable formatted size.
  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────

class PdfSecurityNotifier extends StateNotifier<PdfSecurityState> {
  PdfSecurityNotifier() : super(const PdfSecurityState());

  final PdfSecurityService _service = PdfSecurityService();

  /// Pick a single PDF for security operations.
  Future<void> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        return;
      }

      state = state.copyWith(
        status: SecurityStatus.loading,
        clearError: true,
        clearOutput: true,
        clearProcessed: true,
      );

      final fileData = await File(file.path!).readAsBytes();

      state = state.copyWith(
        status: SecurityStatus.idle,
        originalFileName: file.name,
        originalSize: fileData.length,
        pdfData: fileData,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: SecurityStatus.error,
        errorMessage: 'Failed to load PDF: $e',
      );
    }
  }

  /// Switch between protect and unlock modes.
  void setMode(SecurityMode mode) {
    state = state.copyWith(mode: mode, clearProcessed: true, clearOutput: true);
  }

  /// Update permission flags (protect mode only).
  void setPermissions(SecurityPermissions permissions) {
    state = state.copyWith(permissions: permissions);
  }

  /// Protect the PDF with password and permissions.
  Future<void> protectPdf({
    required String userPassword,
    String? ownerPassword,
  }) async {
    if (state.pdfData == null) {
      state = state.copyWith(errorMessage: 'No PDF loaded.');
      return;
    }
    if (userPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Password cannot be empty.');
      return;
    }

    state = state.copyWith(
      status: SecurityStatus.processing,
      clearError: true,
      clearOutput: true,
    );

    try {
      final result = _service.protect(
        pdfData: state.pdfData!,
        userPassword: userPassword,
        ownerPassword: ownerPassword,
        permissions: state.permissions,
      );

      state = state.copyWith(
        status: SecurityStatus.done,
        processedData: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: SecurityStatus.error,
        errorMessage: 'Protection failed: $e',
      );
    }
  }

  /// Unlock a password-protected PDF.
  Future<void> unlockPdf({required String password}) async {
    if (state.pdfData == null) {
      state = state.copyWith(errorMessage: 'No PDF loaded.');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password cannot be empty.');
      return;
    }

    state = state.copyWith(
      status: SecurityStatus.processing,
      clearError: true,
      clearOutput: true,
    );

    try {
      final result = _service.unlock(
        pdfData: state.pdfData!,
        password: password,
      );

      state = state.copyWith(
        status: SecurityStatus.done,
        processedData: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(status: SecurityStatus.error, errorMessage: '$e');
    }
  }

  /// Save the processed PDF to the device.
  Future<String?> saveProcessedPdf(String desiredName) async {
    if (state.processedData == null) {
      return null;
    }
    try {
      final path = await _service.saveToDevice(
        state.processedData!,
        desiredName,
      );
      state = state.copyWith(outputPath: path);
      return path;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Save failed: $e');
      return null;
    }
  }

  void reset() => state = const PdfSecurityState();
  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ─────────────────────────────────────────────────────────────

final pdfSecurityProvider =
    StateNotifierProvider<PdfSecurityNotifier, PdfSecurityState>(
      (ref) => PdfSecurityNotifier(),
    );
