import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/features/trash/domain/entities/trash_item.dart';

class TrashItemCard extends StatelessWidget {
  const TrashItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRestore,
    required this.onDelete,
  });

  final TrashItem item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var d = bytes.toDouble();
    while (d > 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = '${item.deletedAt.year}-${item.deletedAt.month.toString().padLeft(2, '0')}-${item.deletedAt.day.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isSelected ? AppColors.surfaceLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.neonBlue : AppColors.surfaceBorder,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      elevation: isSelected ? 4 : 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / Selection
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelectionMode
                    ? _buildCheckbox()
                    : _buildFileIcon(),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.dirname(item.originalPath),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatBytes(item.sizeBytes),
                          style: const TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '\u2022',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateFormat,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions (only visible when not in selection mode)
              if (!isSelectionMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: AppColors.success),
                      tooltip: 'Restore',
                      onPressed: onRestore,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: AppColors.error),
                      tooltip: 'Delete Permanently',
                      onPressed: onDelete,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() => Container(
      key: const ValueKey('icon'),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.insert_drive_file_outlined,
        color: AppColors.textSecondary,
      ),
    );

  Widget _buildCheckbox() => Container(
      key: const ValueKey('checkbox'),
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.neonBlue)
          : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
    );
}
