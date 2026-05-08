import 'package:flutter/foundation.dart';

enum BatchOperation { compress, merge, protect, imageToPdf }

enum BatchJobStatus { pending, processing, done, failed, skipped }

@immutable
class BatchJob {
  const BatchJob({
    required this.id,
    required this.filePath,
    required this.operation,
    this.status = BatchJobStatus.pending,
    this.outputPath,
    this.error,
  });

  final String id;
  final String filePath;
  final BatchOperation operation;
  final BatchJobStatus status;
  final String? outputPath;
  final String? error;

  String get fileName => filePath.split('/').last.split(r'\').last;

  BatchJob copyWith({
    BatchJobStatus? status,
    String? outputPath,
    String? error,
  }) => BatchJob(
    id: id,
    filePath: filePath,
    operation: operation,
    status: status ?? this.status,
    outputPath: outputPath ?? this.outputPath,
    error: error ?? this.error,
  );
}

@immutable
class BatchState {
  const BatchState({
    this.jobs = const [],
    this.isRunning = false,
    this.currentIndex = 0,
    this.isCancelled = false,
    this.protectPassword = '',
  });

  final List<BatchJob> jobs;
  final bool isRunning;
  final int currentIndex;
  final bool isCancelled;
  final String protectPassword;

  bool get isDone =>
      !isRunning && jobs.isNotEmpty && currentIndex >= jobs.length;

  int get doneCount =>
      jobs.where((j) => j.status == BatchJobStatus.done).length;

  int get failedCount =>
      jobs.where((j) => j.status == BatchJobStatus.failed).length;

  BatchState copyWith({
    List<BatchJob>? jobs,
    bool? isRunning,
    int? currentIndex,
    bool? isCancelled,
    String? protectPassword,
  }) => BatchState(
    jobs: jobs ?? this.jobs,
    isRunning: isRunning ?? this.isRunning,
    currentIndex: currentIndex ?? this.currentIndex,
    isCancelled: isCancelled ?? this.isCancelled,
    protectPassword: protectPassword ?? this.protectPassword,
  );
}
