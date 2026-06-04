import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

/// A premium text/code file viewer with syntax-aware rendering.
///
/// Supports `.txt`, `.json`, `.xml`, `.md` and other plain-text formats.
/// Features word-wrap toggle, line numbers, and share functionality.
class TextViewerScreen extends StatefulWidget {
  const TextViewerScreen({super.key, required this.filePath});

  /// Absolute path to the text file.
  final String filePath;

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  String? _content;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showLineNumbers = true;
  bool _wordWrap = true;

  String get _fileName => p.basename(widget.filePath);
  String get _fileExtension => p.extension(widget.filePath).toLowerCase();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'File not found at the specified path.';
        });
        return;
      }

      final content = await file.readAsString();
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles([
      XFile(widget.filePath),
    ], text: 'Shared from Zenvix');
  }

  Future<void> _copyToClipboard() async {
    if (_content == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _content!));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Returns a display-friendly label for the file type.
  String get _fileTypeLabel {
    switch (_fileExtension) {
      case '.json':
        return 'JSON';
      case '.xml':
        return 'XML';
      case '.md':
        return 'Markdown';
      case '.csv':
        return 'CSV';
      default:
        return 'Text';
    }
  }

  /// Returns accent color based on file type.
  Color get _fileTypeColor {
    switch (_fileExtension) {
      case '.json':
        return AppColors.warning;
      case '.xml':
        return AppColors.accentPink;
      case '.md':
        return AppColors.accentCyan;
      default:
        return AppColors.neonBlue;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _buildAppBar(),
    body: _buildBody(),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.surface,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _fileName,
          style: const TextStyle(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: _fileTypeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _fileTypeLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _fileTypeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_content != null) ...[
              const SizedBox(width: 8),
              Text(
                '${_content!.split('\n').length} lines',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: Icon(
          _showLineNumbers
              ? Icons.format_list_numbered_rounded
              : Icons.format_list_numbered_rtl_rounded,
          size: 20,
        ),
        tooltip: 'Toggle line numbers',
        onPressed: () => setState(() => _showLineNumbers = !_showLineNumbers),
      ),
      IconButton(
        icon: Icon(
          _wordWrap ? Icons.wrap_text_rounded : Icons.short_text_rounded,
          size: 20,
        ),
        tooltip: 'Toggle word wrap',
        onPressed: () => setState(() => _wordWrap = !_wordWrap),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 22),
        color: AppColors.surfaceLight,
        onSelected: (value) {
          switch (value) {
            case 'copy':
              _copyToClipboard();
            case 'share':
              _share();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 12),
                Text(
                  'Copy All',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(
                  Icons.share_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 12),
                Text('Share', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_hasError) {
      return _buildErrorState();
    }
    return _buildContentView();
  }

  Widget _buildLoadingState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppColors.neonBlue),
        SizedBox(height: AppTheme.spacingMD),
        Text(
          'Loading file…',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          const Text(
            'Failed to open file',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              _loadFile();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContentView() {
    final lines = _content!.split('\n');
    final lineCountWidth = '${lines.length}'.length;

    return Container(
      color: AppColors.background,
      child: _wordWrap
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: AppTheme.spacingSM,
              ),
              child: _buildLines(lines, lineCountWidth),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: AppTheme.spacingSM,
                ),
                child: _buildLines(lines, lineCountWidth),
              ),
            ),
    );
  }

  Widget _buildLines(List<String> lines, int lineCountWidth) =>
      SelectableText.rich(
        TextSpan(
          children: List.generate(lines.length, (i) {
            final lineNum = '${i + 1}'.padLeft(lineCountWidth);
            return TextSpan(
              children: [
                if (_showLineNumbers)
                  TextSpan(
                    text: '$lineNum  ',
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                TextSpan(
                  text: '${lines[i]}\n',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.92),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            );
          }),
        ),
      );
}
