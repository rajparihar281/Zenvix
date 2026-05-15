import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/features/trash/application/providers/trash_provider.dart';
import 'package:zenvix/features/trash/presentation/widgets/trash_item_card.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirmAction(BuildContext context, String title, String content, {bool isDestructive = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(content, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isDestructive ? 'Delete' : 'Confirm',
              style: TextStyle(color: isDestructive ? AppColors.error : AppColors.neonBlue),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trashProvider);
    final notifier = ref.read(trashProvider.notifier);

    // Handle error messages
    ref.listen<TrashState>(trashProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        _showSnackbar(context, next.errorMessage!, isError: true);
        notifier.clearError();
      }
    });

    final items = state.filteredItems;
    final isSelectionMode = state.isSelectionMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: state.isSelectionMode
            ? Text('${state.selectedItems.length} Selected')
            : const Text('Trash'),
        leading: state.isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: notifier.clearSelection,
              )
            : null,
        actions: [
          if (state.isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: notifier.selectAll,
            )
          else if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.error),
              tooltip: 'Empty Trash',
              onPressed: () async {
                final confirm = await _confirmAction(
                  context,
                  'Empty Trash',
                  'Are you sure you want to permanently delete all items in the trash? This cannot be undone.',
                  isDestructive: true,
                );
                if (confirm) {
                  await notifier.emptyTrash();
                  if (context.mounted) {
                    _showSnackbar(context, 'Trash emptied');
                  }
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search trash...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: state.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
          : items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.neonBlue,
                  backgroundColor: AppColors.surface,
                  onRefresh: notifier.loadItems,
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: isSelectionMode ? 100 : 20, top: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = state.selectedItems.contains(item.id);

                      return TrashItemCard(
                        item: item,
                        isSelected: isSelected,
                        isSelectionMode: isSelectionMode,
                        onTap: () {
                          if (isSelectionMode) {
                            notifier.toggleSelection(item.id);
                          } else {
                            // Can't open file directly from trash, must restore first
                            _showSnackbar(context, 'Restore file to open it');
                          }
                        },
                        onLongPress: () {
                          if (!isSelectionMode) {
                            notifier.toggleSelection(item.id);
                          }
                        },
                        onRestore: () async {
                          await notifier.restoreItem(item);
                          if (context.mounted) {
                            _showSnackbar(context, 'File restored');
                          }
                        },
                        onDelete: () async {
                          final confirm = await _confirmAction(
                            context,
                            'Delete Permanently',
                            'Are you sure you want to permanently delete "${item.fileName}"? This cannot be undone.',
                            isDestructive: true,
                          );
                          if (confirm) {
                            await notifier.permanentlyDeleteItem(item);
                            if (context.mounted) {
                              _showSnackbar(context, 'File deleted permanently');
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isSelectionMode ? _buildBottomActionBar(context, notifier) : null,
    );
  }

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trash is empty',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deleted files will appear here',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

  Widget _buildBottomActionBar(BuildContext context, TrashNotifier notifier) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.subtleElevation,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () async {
              await notifier.restoreSelected();
              if (context.mounted) {
                _showSnackbar(context, 'Selected items restored');
              }
            },
            icon: const Icon(Icons.restore, color: AppColors.success),
            label: const Text('Restore', style: TextStyle(color: AppColors.success)),
          ),
          Container(width: 1, height: 30, color: AppColors.surfaceBorder),
          TextButton.icon(
            onPressed: () async {
              final confirm = await _confirmAction(
                context,
                'Delete Selected',
                'Are you sure you want to permanently delete the selected items? This cannot be undone.',
                isDestructive: true,
              );
              if (confirm) {
                await notifier.deleteSelected();
                if (context.mounted) {
                  _showSnackbar(context, 'Selected items deleted');
                }
              }
            },
            icon: const Icon(Icons.delete_forever, color: AppColors.error),
            label: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
}
