import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../shared/rexam_wordmark.dart';
import '../domain/auth_state.dart';
import 'providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with WidgetsBindingObserver {
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      if (_isGoogleLoading) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && !ref.read(authProvider).isAuthenticated) {
            setState(() => _isGoogleLoading = false);
          }
        });
      }
    }
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedDefault,
          side: BorderSide(color: context.themeBorder),
        ),
        title: Text(
          title,
          style: AppTypography.screenTitle.copyWith(color: context.themeTextMain),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.bodyMuted.copyWith(
              color: context.themeTextMuted,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final launched = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;

    if (!launched) {
      setState(() => _isGoogleLoading = false);
      final error = ref.read(authProvider).errorMessage ?? 'Google authentication could not be started.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        setState(() => _isGoogleLoading = false);
        if (next.hasCompletedOnboarding) {
          context.go('/discover');
        } else {
          context.go('/profile/wizard');
        }
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.space16),

              // Rexam Logo and Brand Wordmark
              const Center(
                child: RexamWordmark(fontSize: 26.0),
              ),

              const Spacer(flex: 3),

              // Hero Heading
              Text(
                'Your next opportunity\nstarts here.',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge.copyWith(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.2,
                  color: context.themeTextMain,
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Supporting Explanatory Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                child: Text(
                  'Discover exams, check statutory eligibility, track applications and never miss important deadlines.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMuted.copyWith(
                    fontSize: 14.5,
                    height: 1.5,
                    color: context.themeTextMuted,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // Continue with Google Button
              OutlinedButton(
                onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: context.themeCard,
                  side: BorderSide(color: context.themeBorder, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: _isGoogleLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(context.themeTextMain),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleLogo(size: 20),
                          const SizedBox(width: AppDimensions.space12),
                          Text(
                            'Continue with Google',
                            style: AppTypography.button.copyWith(
                              color: context.themeTextMain,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: AppDimensions.space12),

              // Continue with Email Button
              ElevatedButton(
                onPressed: () => context.push('/auth'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: context.isDarkMode ? AppColors.white : AppColors.primaryGreen,
                  foregroundColor: context.isDarkMode ? AppColors.black : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue with Email',
                  style: AppTypography.button.copyWith(
                    color: context.isDarkMode ? AppColors.black : AppColors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // Terms and Privacy Policy Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showLegalDialog(
                      'Terms of Service',
                      'Rexam is a public interest platform aggregating official notifications from recruitment boards across India. All data is deterministically parsed from gazette publications and primary government portals.',
                    ),
                    child: Text(
                      'Terms of Service',
                      style: AppTypography.caption.copyWith(
                        color: context.themeTextMuted,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '   •   ',
                    style: TextStyle(color: context.themeTextSubtle),
                  ),
                  GestureDetector(
                    onTap: () => _showLegalDialog(
                      'Privacy Policy',
                      'Your educational background and category data are stored encrypted in private candidate profiles for local eligibility evaluation. We never sell or share candidate data with third-party coaching institutes.',
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: AppTypography.caption.copyWith(
                        color: context.themeTextMuted,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space12),
            ],
          ),
        ),
      ),
    );
  }
}
