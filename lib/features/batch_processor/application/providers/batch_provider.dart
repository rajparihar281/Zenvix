import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/batch_processor/data/services/batch_processing_service.dart';
import 'package:zenvix/features/batch_processor/domain/models/batch_job.dart';

class BatchNotifier extends StateNotifier<BatchState> {
  BatchNotifier() : super(const BatchState());

  final BatchProcessingService _service = BatchProcessingService();

  // ── Selection ────────────────────────────────────────────────────────

  final List<String> _selectedPaths = [];

  List<String> get selectedPaths => List.unmodifiable(_selectedPaths);

  void toggleSelection(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    // Notify listeners by emitting a new state copy.
    state = state.copyWith();
  }

  bool isSelected(String path) => _selectedPaths.contains(path);

  void clearSelection() {
    _selectedPaths.clear();
    state = state.copyWith();
  }

  void setProtectPassword(String password) {
    state = state.copyWith(protectPassword: password);
  }

  // ── Queue execution ──────────────────────────────────────────────────

  /// Builds jobs from current selection and starts processing.
  Future<void> startBatch(BatchOperation operation) async {
    if (_selectedPaths.isEmpty) {
      return;
    }

    if (operation == BatchOperation.merge) {
      await _runMerge();
      return;
    }

    final jobs = _selectedPaths
        .asMap()
        .entries
        .map(
          (e) => BatchJob(
            id: '${e.key}_${DateTime.now().millisecondsSinceEpoch}',
            filePath: e.value,
            operation: operation,
          ),
        )
        .toList();

    state = BatchState(
      jobs: jobs,
      isRunning: true,
      protectPassword: state.protectPassword,
    );

    for (var i = 0; i < jobs.length; i++) {
      if (state.isCancelled) {
        break;
      }

      state = state.copyWith(currentIndex: i);

      final updated = await _service.processJob(
        jobs[i],
        protectPassword: state.protectPassword,
      );

      final updatedJobs = List<BatchJob>.from(state.jobs);
      updatedJobs[i] = updated;
      state = state.copyWith(jobs: updatedJobs);
    }

    state = state.copyWith(
      isRunning: false,
      currentIndex: state.jobs.length,
    );
  }

  Future<void> _runMerge() async {
    final mergeJob = BatchJob(
      id: 'merge_${DateTime.now().millisecondsSinceEpoch}',
      filePath: _selectedPaths.first,
      operation: BatchOperation.merge,
    );

    state = BatchState(
      jobs: [mergeJob],
      isRunning: true,
      protectPassword: state.protectPassword,
    );

    try {
      final outputPath = await _service.mergeAll(_selectedPaths);
      final done = mergeJob.copyWith(
        status: BatchJobStatus.done,
        outputPath: outputPath,
      );
      state = state.copyWith(
        jobs: [done],
        isRunning: false,
        currentIndex: 1,
      );
    } on Exception catch (e) {
      final failed = mergeJob.copyWith(
        status: BatchJobStatus.failed,
        error: e.toString(),
      );
      state = state.copyWith(
        jobs: [failed],
        isRunning: false,
        currentIndex: 1,
      );
    }
  }

  void cancel() {
    state = state.copyWith(isCancelled: true, isRunning: false);
  }

  void reset() {
    _selectedPaths.clear();
    state = const BatchState();
  }
}

final batchProvider = StateNotifierProvider<BatchNotifier, BatchState>(
  (ref) => BatchNotifier(),
);
