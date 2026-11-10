import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/branding.dart';
import '../../../core/theme/app_typography.dart';
import 'providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    // 1.4-second branded loading transition
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      if (authState.hasCompletedOnboarding) {
        context.go('/discover');
      } else {
        context.go('/profile/wizard');
      }
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Official Rexam Logo
            AppBranding.logoImage(
              size: 64,
            ),
            const SizedBox(height: AppDimensions.space20),

            // REXAM Wordmark (Preserved for tests)
            Text(
              AppBranding.brandName,
              style: AppTypography.brandTitle.copyWith(
                fontSize: 26,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w800,
                color: context.themeTextMain,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),

            // Subtitle (Preserved for tests)
            Text(
              'Indian Examination & Opportunity Intelligence',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: context.themeTextMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space40),

            // Restrained emerald loading indicator
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
