import 'package:flutter/material.dart';
import 'package:zenvix/features/batch_processor/presentation/screens/batch_progress_screen.dart';
import 'package:zenvix/features/documents/screens/document_preview_screen.dart';
import 'package:zenvix/features/home/screens/home_screen.dart';
import 'package:zenvix/features/image_to_pdf/screens/image_to_pdf_screen.dart';
import 'package:zenvix/features/my_files/screens/my_files_screen.dart';
import 'package:zenvix/features/my_files/screens/pdf_viewer_picker_screen.dart';
import 'package:zenvix/features/pdf_combiner/screens/pdf_combiner_screen.dart';
import 'package:zenvix/features/pdf_compression/presentation/screens/pdf_compression_screen.dart';
import 'package:zenvix/features/pdf_page_manager/ui/pdf_page_manager_screen.dart';
import 'package:zenvix/features/pdf_security/presentation/screens/pdf_security_screen.dart';
import 'package:zenvix/features/pdf_viewer/screens/pdf_viewer_screen.dart';
import 'package:zenvix/features/pdf_watermark/presentation/screens/pdf_watermark_screen.dart';
import 'package:zenvix/features/qr_tools/presentation/screens/qr_tools_screen.dart';
import 'package:zenvix/features/text_viewer/screens/text_viewer_screen.dart';
import 'package:zenvix/features/trash/presentation/screens/trash_screen.dart';
import 'package:zenvix/shared/splash_screen.dart';

// ignore_for_file: avoid_classes_with_only_static_members

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(const HomeScreen(), settings);
      case '/splashscreen':
        return _buildRoute(const SplashScreen(), settings);
      case '/image-to-pdf':
        return _buildRoute(const ImageToPdfScreen(), settings);
      case '/pdf-combiner':
        return _buildRoute(const PdfCombinerScreen(), settings);
      case '/pdf-compression':
        return _buildRoute(const PdfCompressionScreen(), settings);
      case '/pdf-page-manager':
        return _buildRoute(const PdfPageManagerScreen(), settings);
      case '/my-files':
        return _buildRoute(const MyFilesScreen(), settings);
      case '/pdf-security':
        return _buildRoute(const PdfSecurityScreen(), settings);
      case '/qr-tools':
        return _buildRoute(const QrToolsScreen(), settings);
      case '/batch-progress':
        return _buildRoute(const BatchProgressScreen(), settings);
      case '/pdf-watermark':
        return _buildRoute(const PdfWatermarkScreen(), settings);
      case '/trash':
        return _buildRoute(const TrashScreen(), settings);
      case '/pdf-viewer':
        final args = settings.arguments;
        if (args is Map<String, String> && args['filePath'] != null) {
          return _buildRoute(
            PdfViewerScreen(filePath: args['filePath']!),
            settings,
          );
        }
        return _buildRoute(const PdfViewerPickerScreen(), settings);
      case '/text-viewer':
        final args = settings.arguments;
        if (args is Map<String, String> && args['filePath'] != null) {
          return _buildRoute(
            TextViewerScreen(filePath: args['filePath']!),
            settings,
          );
        }
        return _buildRoute(const HomeScreen(), settings);
      case '/document-preview':
        final args = settings.arguments;
        if (args is Map<String, String> && args['filePath'] != null) {
          return _buildRoute(
            DocumentPreviewScreen(filePath: args['filePath']!),
            settings,
          );
        }
        return _buildRoute(const HomeScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) => PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
