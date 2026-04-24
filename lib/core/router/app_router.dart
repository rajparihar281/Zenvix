import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/image_to_pdf/screens/image_to_pdf_screen.dart';
import '../../features/pdf_combiner/screens/pdf_combiner_screen.dart';
import '../../features/my_files/screens/my_files_screen.dart';

/// Generates routes from named paths.
///
/// Each tool registered in [tool_registry.dart] should have a matching
/// case here.  Using [onGenerateRoute] keeps navigation decoupled from
/// the UI layer.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(const HomeScreen(), settings);
      case '/image-to-pdf':
        return _buildRoute(const ImageToPdfScreen(), settings);
      case '/pdf-combiner':
        return _buildRoute(const PdfCombinerScreen(), settings);
      case '/my-files':
        return _buildRoute(const MyFilesScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  /// Wraps a page in a [MaterialPageRoute] with a smooth slide transition.
  static PageRouteBuilder<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
