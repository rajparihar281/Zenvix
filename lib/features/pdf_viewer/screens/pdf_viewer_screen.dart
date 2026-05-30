import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_viewer/widget/pdf_loading_widget.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfViewerController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _fileName =>
      widget.filePath.split('/').last.split(r'\').last;

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(widget.filePath)],
      text: 'Shared from Zenvix',
    );
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      title: Text(
        _fileName,
        style: const TextStyle(fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, size: 22),
          tooltip: 'Share',
          onPressed: _share,
        ),
        const SizedBox(width: 4),
      ],
    ),
    body: Stack(
      children: [
        if (!_hasError)
          SfPdfViewer.file(
            File(widget.filePath),
            controller: _controller,
            onDocumentLoaded: (_) => setState(() => _isLoading = false),
            onDocumentLoadFailed: (details) => setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = details.description;
            }),
          ),
        if (_isLoading && !_hasError) const PdfLoadingWidget(),
        if (_hasError) _ErrorView(message: _errorMessage, onRetry: _retry),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
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
            'Failed to open PDF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
