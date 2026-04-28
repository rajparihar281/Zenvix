import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/qr_tools/domain/models/qr_result.dart';

enum ScannerStatus { idle, scanning, paused, permissionDenied }

class QrScannerState {
  const QrScannerState({
    this.status = ScannerStatus.idle,
    this.result,
    this.errorMessage,
  });

  final ScannerStatus status;
  final QrResult? result;
  final String? errorMessage;

  QrScannerState copyWith({
    ScannerStatus? status,
    QrResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) => QrScannerState(
    status: status ?? this.status,
    result: clearResult ? null : (result ?? this.result),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class QrScannerNotifier extends StateNotifier<QrScannerState> {
  QrScannerNotifier() : super(const QrScannerState());

  void startScanning() {
    state = state.copyWith(
      status: ScannerStatus.scanning,
      clearResult: true,
      clearError: true,
    );
  }

  void onPermissionDenied() {
    state = state.copyWith(
      status: ScannerStatus.permissionDenied,
      errorMessage: 'Camera permission denied. Please grant access in Settings.',
    );
  }

  void onDetected(String rawValue) {
    if (state.status != ScannerStatus.scanning) {
      return;
    }
    state = state.copyWith(
      status: ScannerStatus.paused,
      result: QrResult.fromRaw(rawValue),
    );
  }

  void resumeScanning() {
    state = state.copyWith(
      status: ScannerStatus.scanning,
      clearResult: true,
      clearError: true,
    );
  }

  void reset() => state = const QrScannerState();
  void clearError() => state = state.copyWith(clearError: true);
}

final qrScannerProvider =
    StateNotifierProvider<QrScannerNotifier, QrScannerState>(
      (ref) => QrScannerNotifier(),
    );
