import 'dart:async';

import 'package:flutter/services.dart';

/// Bridges Android's ACTION_VIEW intents from [MainActivity] to Flutter.
///
/// [receive_sharing_intent] only handles ACTION_SEND. This service covers
/// ACTION_VIEW (e.g. tapping a file in Downloads, Drive, or a file manager).
class ViewIntentService {
  ViewIntentService._();

  static const _channel = MethodChannel('com.Zenvix.Zenvix/incoming_file');

  static final _controller = StreamController<String>.broadcast();

  /// Stream of raw URI strings received via ACTION_VIEW while the app is
  /// running (warm-start / onNewIntent path).
  static Stream<String> get uriStream => _controller.stream;

  /// Must be called once during app initialisation (before runApp).
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileReceived') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) {
          _controller.add(uri);
        }
      }
    });
  }

  /// Returns the URI that launched the app from a terminated state, or null.
  static Future<String?> getInitialUri() async {
    try {
      final result = await _channel.invokeMethod<String>('getInitialFile');
      return result;
    } on PlatformException {
      return null;
    }
  }

  static void dispose() => _controller.close();
}
