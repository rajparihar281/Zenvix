import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:zenvix/core/theme/app_colors.dart';

class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<bool>(
        // ignore: avoid_slow_async_io
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.electricPurple),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return PdfPreview(
              build: (format) => file.readAsBytesSync(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: fileName,
            );
          }

          return const Center(
            child: Text(
              'File not found or corrupted.',
              style: TextStyle(color: AppColors.error),
            ),
          );
        },
      ),
    );
  }
}
