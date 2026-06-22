import 'package:flutter/material.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Icon: scale + fade in
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;

  // App name: slide up + fade in
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;

  // Tagline: fade in
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _iconScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.elasticOut),
      ),
    );

    _iconOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );

    _nameOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animated icon ──
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _iconOpacity.value,
              child: Transform.scale(scale: _iconScale.value, child: child),
            ),
            child: Image.asset(
              'assets/logo/logo.png',
              width: 88,
              height: 88,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // ── Animated app name ──
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => FadeTransition(
              opacity: _nameOpacity,
              child: SlideTransition(position: _nameSlide, child: child),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.accentGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingSM),

          // ── Animated tagline ──
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) =>
                Opacity(opacity: _taglineOpacity.value, child: child),
            child: const Text(
              'Your pocket toolkit, forged for power.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
