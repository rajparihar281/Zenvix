import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/batch_processor/application/providers/batch_provider.dart';
import 'package:zenvix/features/batch_processor/domain/models/batch_job.dart';

class BatchProgressScreen extends ConsumerWidget {
  const BatchProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchProvider);

    return PopScope(
      canPop: !state.isRunning,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Batch Processing'),
          automaticallyImplyLeading: !state.isRunning,
          actions: [
            if (state.isRunning)
              TextButton(
                onPressed: () => ref.read(batchProvider.notifier).cancel(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            _ProgressHeader(state: state),
            Expanded(child: _JobList(state: state)),
            if (state.isDone) _DoneFooter(state: state),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final BatchState state;

  @override
  Widget build(BuildContext context) {
    final total = state.jobs.length;
    final current = state.currentIndex.clamp(0, total);
    final progress = total == 0 ? 0.0 : current / total;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.isRunning
                    ? 'Processing ${current + 1}/$total'
                    : state.isCancelled
                    ? 'Cancelled'
                    : state.isDone
                    ? 'Completed'
                    : 'Ready',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                '${state.doneCount} done · ${state.failedCount} failed',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            child: LinearProgressIndicator(
              value: state.isRunning ? progress : (state.isDone ? 1.0 : 0.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isCancelled ? AppColors.error : AppColors.neonBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.state});

  final BatchState state;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(AppTheme.spacingMD),
    itemCount: state.jobs.length,
    itemBuilder: (context, index) {
      final job = state.jobs[index];
      final isCurrent = state.isRunning && index == state.currentIndex;
      return _JobTile(job: job, isCurrent: isCurrent);
    },
  );
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.isCurrent});

  final BatchJob job;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(job.status, isCurrent);

    return AnimatedContainer(
      duration: AppTheme.animMedium,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.neonBlue.withValues(alpha: 0.06)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isCurrent
              ? AppColors.neonBlue.withValues(alpha: 0.3)
              : AppColors.surfaceBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: isCurrent
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neonBlue,
                  )
                : Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (job.error != null)
                  Text(
                    job.error!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _StatusBadge(status: job.status, isCurrent: isCurrent),
        ],
      ),
    );
  }

  (IconData, Color) _iconAndColor(BatchJobStatus status, bool current) {
    if (current) {
      return (Icons.hourglass_top_rounded, AppColors.neonBlue);
    }
    switch (status) {
      case BatchJobStatus.done:
        return (Icons.check_circle_rounded, AppColors.success);
      case BatchJobStatus.failed:
        return (Icons.error_rounded, AppColors.error);
      case BatchJobStatus.skipped:
        return (Icons.skip_next_rounded, AppColors.textTertiary);
      case BatchJobStatus.processing:
        return (Icons.hourglass_top_rounded, AppColors.neonBlue);
      case BatchJobStatus.pending:
        return (Icons.radio_button_unchecked_rounded, AppColors.textTertiary);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isCurrent});

  final BatchJobStatus status;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCurrent || status == BatchJobStatus.pending) {
      return const SizedBox.shrink();
    }

    final (label, color) = switch (status) {
      BatchJobStatus.done => ('Done', AppColors.success),
      BatchJobStatus.failed => ('Failed', AppColors.error),
      BatchJobStatus.skipped => ('Skipped', AppColors.textTertiary),
      _ => ('', AppColors.textTertiary),
    };

    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DoneFooter extends ConsumerWidget {
  const _DoneFooter({required this.state});

  final BatchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.all(AppTheme.spacingMD),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${state.doneCount} succeeded · ${state.failedCount} failed',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(batchProvider.notifier).reset();
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    ),
  );
}
