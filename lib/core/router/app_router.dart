import 'package:flutter/material.dart';
import 'package:zenvix/features/home/screens/home_screen.dart';
import 'package:zenvix/features/image_to_pdf/screens/image_to_pdf_screen.dart';
import 'package:zenvix/features/my_files/screens/my_files_screen.dart';
import 'package:zenvix/features/pdf_combiner/screens/pdf_combiner_screen.dart';
import 'package:zenvix/features/pdf_compression/presentation/screens/pdf_compression_screen.dart';
import 'package:zenvix/features/pdf_page_manager/ui/pdf_page_manager_screen.dart';
import 'package:zenvix/features/pdf_security/presentation/screens/pdf_security_screen.dart';
import 'package:zenvix/features/qr_tools/presentation/screens/qr_tools_screen.dart';

// ignore_for_file: avoid_classes_with_only_static_members

class AppRouter {
  AppRouter._();
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(const HomeScreen(), settings);
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
      case '/pdf-compression':
        return _buildRoute(const PdfCompressionScreen(), settings);
      case '/pdf-security':
        return _buildRoute(const PdfSecurityScreen(), settings);
      case '/qr-tools':
        return _buildRoute(const QrToolsScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  /// Wraps a page in a [MaterialPageRoute] with a smooth slide transition.
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
