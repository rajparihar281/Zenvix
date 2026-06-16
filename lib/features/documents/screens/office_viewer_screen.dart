import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';

class OfficeViewerScreen extends StatelessWidget {
  const OfficeViewerScreen({super.key, required this.filePath});

  final String filePath;

  String get _fileName => p.basename(filePath);

  Future<void> _share() async {
    await Share.shareXFiles([XFile(filePath)], text: 'Shared from Zenvix');
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
      body: FutureBuilder<Uint8List>(
        future: File(filePath).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load document:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Document is empty.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return MicrosoftViewer(
            snapshot.data!,
            false,
          );
        },
      ),
    );
}
