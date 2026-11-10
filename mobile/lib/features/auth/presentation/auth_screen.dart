import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../shared/rexam_wordmark.dart';
import '../domain/auth_state.dart';
import 'providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;

  const AuthScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with WidgetsBindingObserver {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      if (_isLoading) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && !ref.read(authProvider).isAuthenticated) {
            setState(() => _isLoading = false);
          }
        });
      }
    }
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password) || RegExp(r'[!@#\$&*~]').hasMatch(password)) strength++;
    return strength;
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.mutedGreen;
      case 4:
        return AppColors.primaryGreen;
      default:
        return Colors.transparent;
    }
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && !_termsAccepted) {
      setState(() => _localError = 'Please accept the Terms of Service to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _localError = null;
    });

    final notifier = ref.read(authProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await notifier.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else {
      success = await notifier.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final authState = ref.read(authProvider);
      if (_isSignUp || !authState.hasCompletedOnboarding) {
        context.go('/profile/wizard');
      } else {
        context.go('/discover');
      }
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Authentication could not be completed.';
      setState(() => _localError = error);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _localError = null;
    });

    final launched = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;

    if (!launched) {
      setState(() {
        _isLoading = false;
        _localError = ref.read(authProvider).errorMessage ?? 'Google authentication could not be started.';
      });
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isSending = false;
    String? message;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.themeCard,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedDefault,
            side: BorderSide(color: context.themeBorder),
          ),
          title: Text(
            'Reset Password',
            style: AppTypography.screenTitle.copyWith(color: context.themeTextMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your registered email address. Password reset instructions will be sent via official Supabase auth service.',
                style: AppTypography.bodyMuted.copyWith(color: context.themeTextMuted),
              ),
              const SizedBox(height: AppDimensions.space16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.themeTextMain),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(LucideIcons.mail, size: 18),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppDimensions.space12),
                Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains('dispatched') ? AppColors.primaryGreen : AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setDialogState(() => message = 'Please enter a valid email address.');
                        return;
                      }

                      setDialogState(() => isSending = true);
                      try {
                        await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
                        setDialogState(() {
                          isSending = false;
                          message = 'Recovery email dispatched. Check your inbox.';
                        });
                      } catch (e) {
                        setDialogState(() {
                          isSending = false;
                          message = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Recovery Email'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        setState(() => _isLoading = false);
        if (_isSignUp || !next.hasCompletedOnboarding) {
          context.go('/profile/wizard');
        } else {
          context.go('/discover');
        }
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        setState(() {
          _isLoading = false;
          _localError = next.errorMessage;
        });
      }
    });

    final passwordStrength = _calculatePasswordStrength(_passwordController.text);

    return PopScope(
      canPop: !_isSignUp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSignUp) {
          setState(() {
            _isSignUp = false;
            _localError = null;
          });
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/welcome');
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.themeTextMain),
            onPressed: () {
              if (_isSignUp) {
                setState(() => _isSignUp = false);
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
              }
            },
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space8,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wordmark & Emblem
                const Center(
                  child: RexamWordmark(fontSize: 22.0, showSubtitle: false),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Form Heading
                Text(
                  _isSignUp ? 'Create your Rexam account' : 'Welcome back',
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextMain,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  _isSignUp
                      ? 'Set up your candidate profile to evaluate your eligibility across all Indian recruitment examinations.'
                      : 'Sign in to access your saved opportunities and application deadlines.',
                  style: AppTypography.bodyMuted.copyWith(color: context.themeTextMuted),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Error Banner
                if (_localError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: AppDimensions.roundedSmall,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.error),
                        const SizedBox(width: AppDimensions.space8),
                        Expanded(
                          child: Text(
                            _localError!,
                            style: AppTypography.caption.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Full Name (Only in Sign Up)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    style: TextStyle(color: context.themeTextMain),
                    decoration: const InputDecoration(
                      labelText: 'Full Legal Name',
                      hintText: 'e.g. Vikramaditya Rathore',
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Full legal name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Email Address
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: context.themeTextMain),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(LucideIcons.mail, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email address is required.';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                  style: TextStyle(color: context.themeTextMain),
                  onChanged: (_) {
                    if (_isSignUp) setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required.';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),

                // Password Strength Indicator (Sign Up Only)
                if (_isSignUp && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: passwordStrength / 4.0,
                            backgroundColor: context.themeSurfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(passwordStrength)),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Text(
                        _getStrengthLabel(passwordStrength),
                        style: AppTypography.caption.copyWith(
                          color: _getStrengthColor(passwordStrength),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // Forgot Password Link (Sign In Only)
                if (!_isSignUp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Confirm Password (Sign Up Only)
                if (_isSignUp) ...[
                  const SizedBox(height: AppDimensions.space16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: context.themeTextMain),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (val) {
                      if (_isSignUp && val != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Terms Acceptance Checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          activeColor: AppColors.primaryGreen,
                          checkColor: AppColors.white,
                          side: BorderSide(color: context.themeBorder),
                          onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service & Privacy Policy',
                          style: AppTypography.caption.copyWith(color: context.themeTextMuted),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppDimensions.space24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Divider: OR
                Row(
                  children: [
                    Expanded(child: Divider(color: context.themeBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                      child: Text(
                        'OR',
                        style: AppTypography.caption.copyWith(
                          color: context.themeTextSubtle,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.themeBorder)),
                  ],
                ),
                const SizedBox(height: AppDimensions.space20),

                // Continue with Google Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.themeCard,
                    side: BorderSide(color: context.themeBorder),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 20),
                      const SizedBox(width: AppDimensions.space12),
                      Text(
                        'Continue with Google',
                        style: AppTypography.button.copyWith(color: context.themeTextMain),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Toggle Login / Sign Up Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
                      style: AppTypography.caption.copyWith(color: context.themeTextMuted),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _localError = null;
                        });
                      },
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Create Account',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
