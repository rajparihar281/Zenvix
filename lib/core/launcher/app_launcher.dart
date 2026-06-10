import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:zenvix/core/router/app_router.dart';
import 'package:zenvix/core/services/incoming_file_service.dart';
import 'package:zenvix/core/services/view_intent_service.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/features/pdf_viewer/screens/pdf_viewer_screen.dart';
import 'package:zenvix/features/text_viewer/screens/text_viewer_screen.dart';

/// Root widget that owns the [NavigatorState] and listens for incoming
/// document intents from Android's "Open with" / share sheet.
///
/// Handles both:
/// - ACTION_SEND via `receive_sharing_intent`
/// - ACTION_VIEW via [ViewIntentService] MethodChannel
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
  StreamSubscription<List<SharedMediaFile>>? _sendIntentSub;
  StreamSubscription<String>? _viewIntentSub;

  // Guards against the same file being routed multiple times within a
  // short window (both getInitialMedia and the stream can fire together).
  String? _lastHandledPath;
  DateTime? _lastHandledAt;

  bool _isDuplicate(String path) {
    final now = DateTime.now();
    if (_lastHandledPath == path &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 3)) {
      return true;
    }
    _lastHandledPath = path;
    _lastHandledAt = now;
    return false;
  }

  @override
  void initState() {
    super.initState();
    ViewIntentService.init();
    _handleInitialIntents();
    _listenForIntents();
  }

  @override
  void dispose() {
    _sendIntentSub?.cancel();
    _viewIntentSub?.cancel();
    super.dispose();
  }

  // ── Cold-start: app launched via intent ─────────────────────────────

  Future<void> _handleInitialIntents() async {
    // ACTION_VIEW cold-start (MainActivity cached the URI).
    final viewUri = await ViewIntentService.getInitialUri();
    if (viewUri != null) {
      final incoming = await IncomingFileService.resolveFromUri(viewUri);
      if (incoming != null && !_isDuplicate(incoming.path)) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _routeFile(incoming),
        );
        return;
      }
    }

    // ACTION_SEND cold-start.
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (files.isEmpty) {
        return;
      }
      final incoming = await IncomingFileService.resolveFirstFile(files);
      if (incoming == null || _isDuplicate(incoming.path)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _routeFile(incoming));
      await ReceiveSharingIntent.instance.reset();
    } on Exception catch (e) {
      debugPrint('[AppLauncher] Initial ACTION_SEND error: $e');
    }
  }

  // ── Warm-start: app receives intent while running ────────────────────

  void _listenForIntents() {
    // ACTION_VIEW stream.
    _viewIntentSub = ViewIntentService.uriStream.listen((uri) async {
      final incoming = await IncomingFileService.resolveFromUri(uri);
      if (incoming != null && !_isDuplicate(incoming.path)) {
        _routeFile(incoming);
      }
    });

    // ACTION_SEND stream.
    _sendIntentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) async {
        if (files.isEmpty) {
          return;
        }
        final incoming = await IncomingFileService.resolveFirstFile(files);
        if (incoming == null || _isDuplicate(incoming.path)) {
          return;
        }
        _routeFile(incoming);
        await ReceiveSharingIntent.instance.reset();
      },
      onError: (Object e) =>
          debugPrint('[AppLauncher] ACTION_SEND stream error: $e'),
    );
  }

  // ── File routing ─────────────────────────────────────────────────────

  void _routeFile(IncomingFile file) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    debugPrint(
      '[AppLauncher] Routing ${file.fileName} → ${file.category.name}',
    );

    switch (file.category) {
      case IncomingFileCategory.pdf:
        navigator.push(
          MaterialPageRoute<PdfViewerScreen>(
            builder: (_) => PdfViewerScreen(filePath: file.path),
          ),
        );

      case IncomingFileCategory.text:
        navigator.push(
          MaterialPageRoute<TextViewerScreen>(
            builder: (_) => TextViewerScreen(filePath: file.path),
          ),
        );

      case IncomingFileCategory.document:
      case IncomingFileCategory.presentation:
      case IncomingFileCategory.spreadsheet:
      case IncomingFileCategory.unsupported:
        _showUnsupportedSnackBar(file.fileName);
    }
  }

  void _showUnsupportedSnackBar(String fileName) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          'Unsupported file: $fileName',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.neonBlue,
          onPressed: () {},
        ),
      ),
    );
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
