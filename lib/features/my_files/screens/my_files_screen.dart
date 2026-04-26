import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/my_files/models/my_file_item.dart';
import 'package:zenvix/features/my_files/providers/my_files_provider.dart';
import 'package:zenvix/features/my_files/screens/pdf_viewer_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';

class MyFilesScreen extends ConsumerStatefulWidget {
  const MyFilesScreen({super.key});

  @override
  ConsumerState<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends ConsumerState<MyFilesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh files when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myFilesProvider.notifier).loadFiles();
    });
  }

  void _showRenameDialog(MyFileItem file) {
    final controller = TextEditingController(
      text: file.name.replaceAll('.pdf', ''),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename File',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'New Name',
            suffixText: '.pdf',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.electricPurple),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricPurple,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty &&
                  newName != file.name.replaceAll('.pdf', '')) {
                await ref
                    .read(myFilesProvider.notifier)
                    .renameFile(file.path, newName);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MyFileItem file) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete File?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${file.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(myFilesProvider.notifier).deleteFile(file.path);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(MyFileItem file) async {
    try {
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Generated with Zenvix');
    } on Exception catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to share: $e');
      }
    }
  }

  void _openFile(MyFileItem file) {
    Navigator.push(
      context,
      MaterialPageRoute<PdfViewerScreen>(
        builder: (_) =>
            PdfViewerScreen(filePath: file.path, fileName: file.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myFilesProvider);

    // Listen for errors
    ref.listen<MyFilesState>(myFilesProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        ref.read(myFilesProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myFiles),
        actions: [
          PopupMenuButton<FileSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            onSelected: (option) =>
                ref.read(myFilesProvider.notifier).setSortOption(option),
            itemBuilder: (context) => [
              _buildSortItem(
                FileSortOption.newest,
                'Newest First',
                state.sortOption,
              ),
              _buildSortItem(
                FileSortOption.oldest,
                'Oldest First',
                state.sortOption,
              ),
              _buildSortItem(
                FileSortOption.nameAsc,
                'Name (A-Z)',
                state.sortOption,
              ),
              _buildSortItem(
                FileSortOption.nameDesc,
                'Name (Z-A)',
                state.sortOption,
              ),
              _buildSortItem(
                FileSortOption.sizeDesc,
                'Largest First',
                state.sortOption,
              ),
              _buildSortItem(
                FileSortOption.sizeAsc,
                'Smallest First',
                state.sortOption,
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  PopupMenuItem<FileSortOption> _buildSortItem(
    FileSortOption option,
    String label,
    FileSortOption current,
  ) => PopupMenuItem(
    value: option,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        if (current == option)
          const Icon(Icons.check, size: 18, color: AppColors.neonBlue),
      ],
    ),
  );

  Widget _buildBody(MyFilesState state) {
    if (state.isLoading && state.files.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.electricPurple),
      );
    }

    if (state.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricPurple.withValues(alpha: 0.2),
                    AppColors.neonBlue.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.electricPurple.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: AppColors.neonBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            const Text(
              AppStrings.emptyFilesTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
              child: Text(
                AppStrings.emptyFilesSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myFilesProvider.notifier).loadFiles(),
      color: AppColors.neonBlue,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          // Time formatting
          final diff = DateTime.now().difference(file.modified);
          final timeStr = diff.inDays > 0
              ? '${diff.inDays}d ago'
              : (diff.inHours > 0 ? '${diff.inHours}h ago' : 'Just now');

          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
            color: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              side: BorderSide(
                color: AppColors.surfaceBorder.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              onTap: () => _openFile(file),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.electricPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.electricPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${file.formattedSize}  Â·  $timeStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (value) {
                        if (value == 'open') {
                          _openFile(file);
                        } else if (value == 'rename') {
                          _showRenameDialog(file);
                        } else if (value == 'share') {
                          _shareFile(file);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(file);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Open')),
                        const PopupMenuItem(
                          value: 'share',
                          child: Text('Share'),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
