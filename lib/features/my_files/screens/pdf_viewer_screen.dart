import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = File(widget.filePath).readAsBytes();
  }

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(widget.filePath)],
      text: 'Shared from Zenvix',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.fileName,
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
    body: FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.electricPurple),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                const Text(
                  'Could not load PDF.',
                  style: TextStyle(color: AppColors.error, fontSize: 15),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  snapshot.error?.toString() ?? 'File not found.',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final bytes = snapshot.data!;

        return PdfPreview(
          build: (_) => bytes,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          pdfFileName: widget.fileName,
          loadingWidget: const Center(
            child: CircularProgressIndicator(color: AppColors.electricPurple),
          ),
          onError: (context, error) => Center(
            child: Text(
              'Render error: $error',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          scrollViewDecoration: const BoxDecoration(
            color: AppColors.background,
          ),
          previewPageMargin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        );
      },
    ),
  );
}
