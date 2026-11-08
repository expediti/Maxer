import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/rexam_wordmark.dart';
import 'providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isGoogleLoading = false;

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTypography.screenTitle),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.bodyMuted.copyWith(height: 1.5),
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
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      context.go('/discover');
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Google sign-in could not be completed.';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              // Rexam Brand Wordmark & Emblem
              const Center(
                child: RexamWordmark(fontSize: 28.0),
              ),

              const Spacer(flex: 2),

              // Hero Heading
              Text(
                'Your next opportunity starts here.',
                textAlign: TextAlign.center,
                style: AppTypography.screenTitle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Supporting Text
              Text(
                'Discover verified examinations, evaluate your eligibility deterministically, and never miss critical application deadlines across India.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted.copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Continue with Google Button
              OutlinedButton(
                onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google G Icon / Emblem
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Text(
                            'Continue with Google',
                            style: AppTypography.button.copyWith(
                              color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Continue with Email Button
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Continue with Email'),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Explore as Guest
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signInAsGuest();
                  if (!context.mounted) return;
                  context.go('/discover');
                },
                child: Text(
                  'Explore as Guest',
                  style: AppTypography.button.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Terms and Privacy Policy Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showLegalDialog(
                      'Terms of Service',
                      'REXAM provides examination alerts and deterministic eligibility analysis based on publicly published official recruitment gazettes and notices.\n\nCandidates must independently verify their eligibility on the recruiting authority\'s official application portal.',
                    ),
                    child: Text(
                      'Terms of Service',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryBlue,
                        decoration: TextDecoration.underline,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    '  •  ',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLegalDialog(
                      'Privacy Policy',
                      'Your personal demographics and educational qualifications are used exclusively for computing deterministic examination eligibility and storing application milestones.\n\nAll candidate records are protected by Row Level Security in Supabase.',
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryBlue,
                        decoration: TextDecoration.underline,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space8),
            ],
          ),
        ),
      ),
    );
  }
}
