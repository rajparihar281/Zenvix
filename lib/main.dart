import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/launcher/app_launcher.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: ZenvixApp()));
}

class ZenvixApp extends StatelessWidget {
  const ZenvixApp({super.key});

  @override
  Widget build(BuildContext context) => AppLauncher(
    appTitle: AppStrings.appName,
    theme: AppTheme.theme,
    initialRoute: '/splashscreen',
  );
}
