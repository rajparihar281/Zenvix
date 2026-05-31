import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:zenvix/core/router/app_router.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/features/pdf_viewer/screens/pdf_viewer_screen.dart';

class AppLauncher extends StatefulWidget {
  const AppLauncher({
    super.key,
    required this.appTitle,
    required this.theme,
    required this.initialRoute,
  });

  final String appTitle;
  final ThemeData theme;
  final String initialRoute;

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _intentSub;

  @override
  void initState() {
    super.initState();
    _handleInitialIntent();
    _listenForIntents();
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialIntent() async {
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (files.isEmpty) {
        return;
      }
      final pdfPath = _firstPdfPath(files);
      if (pdfPath == null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPdf(pdfPath));
      await ReceiveSharingIntent.instance.reset();
    } on Exception catch (e) {
      debugPrint('[AppLauncher] Initial intent error: $e');
    }
  }

  void _listenForIntents() {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isEmpty) {
          return;
        }
        final pdfPath = _firstPdfPath(files);
        if (pdfPath == null) {
          return;
        }
        _openPdf(pdfPath);
        ReceiveSharingIntent.instance.reset();
      },
      onError: (Object e) =>
          debugPrint('[AppLauncher] Intent stream error: $e'),
    );
  }

  void _openPdf(String path) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<PdfViewerScreen>(
        builder: (_) => PdfViewerScreen(filePath: path),
      ),
    );
  }

  String? _firstPdfPath(List<SharedMediaFile> files) {
    for (final file in files) {
      final path = file.path;
      if (path.toLowerCase().endsWith('.pdf')) {
        return path;
      }
      if (file.mimeType?.toLowerCase().contains('pdf') == true) {
        return path;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: widget.appTitle,
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigatorKey,
    theme: widget.theme,
    initialRoute: widget.initialRoute,
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (context, child) => ColoredBox(
      color: AppColors.background,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
