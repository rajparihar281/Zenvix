import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/router/app_router.dart';
import 'package:zenvix/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force OLED-friendly system chrome (dark status/nav bars).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: ZenvixApp()));
}

class ZenvixApp extends StatelessWidget {
  const ZenvixApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppStrings.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    initialRoute: '/',
    onGenerateRoute: AppRouter.onGenerateRoute,
  );
}
