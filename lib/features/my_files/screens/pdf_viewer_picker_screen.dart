import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/my_files/screens/pdf_viewer_screen.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

/// Entry point for the PDF Viewer tool from the home screen.
/// Lets the user pick any PDF and opens it in [PdfViewerScreen].
class PdfViewerPickerScreen extends StatefulWidget {
  const PdfViewerPickerScreen({super.key});

  @override
  State<PdfViewerPickerScreen> createState() => _PdfViewerPickerScreenState();
}

class _PdfViewerPickerScreenState extends State<PdfViewerPickerScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _pickAndOpen() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted) {
        return;
      }

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;

      await Navigator.push(
        context,
        MaterialPageRoute<PdfViewerScreen>(
          builder: (_) => PdfViewerScreen(
            filePath: file.path!,
            fileName: file.name,
          ),
        ),
      );
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to open file: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('PDF Viewer'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 48,
                color: AppColors.neonBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'Open any PDF',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Browse, read, and share PDF files from your device',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppTheme.spacingXL),
            NeonButton(
              label: 'Select PDF',
              icon: Icons.upload_file_rounded,
              expanded: false,
              isLoading: _loading,
              onPressed: _pickAndOpen,
            ),
          ],
        ),
      ),
    ),
  );
}
