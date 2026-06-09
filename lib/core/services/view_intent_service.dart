import 'dart:async';

import 'package:flutter/services.dart';

class ViewIntentService {
  ViewIntentService._();

  static const _channel = MethodChannel('com.Zenvix.Zenvix/incoming_file');

  static final _controller = StreamController<String>.broadcast();

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
