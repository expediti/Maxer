import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/rexam_wordmark.dart';
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

class _AuthScreenState extends ConsumerState<AuthScreen> {
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
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password strength calculation: 0 to 4
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
        return Colors.blue;
      case 4:
        return AppColors.success;
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
      if (_isSignUp) {
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

    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go('/discover');
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Google authentication error.';
      setState(() => _localError = error);
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
          title: Text('Reset Password', style: AppTypography.screenTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your registered email address. Password reset instructions will be sent to your inbox.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppDimensions.space16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppDimensions.space12),
                Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains('sent') ? AppColors.success : AppColors.error,
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
                        setDialogState(() => message = 'Please enter a valid email.');
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final passwordStrength = _calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
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
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  _isSignUp
                      ? 'Set up your candidate profile to evaluate your eligibility across all Indian recruitment exams.'
                      : 'Sign in to access your saved bookmarks and application deadlines.',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppDimensions.space24),

                // Error Banner
                if (_localError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppDimensions.roundedSmall,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
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
                    decoration: const InputDecoration(
                      labelText: 'Full Legal Name',
                      hintText: 'e.g. Arjun Sharma',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (val) {
                      if (_isSignUp && (val == null || val.trim().isEmpty)) {
                        return 'Please enter your full name as on Class 10 certificate.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Email
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email address.';
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
                  onChanged: (val) {
                    if (_isSignUp) setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: _isSignUp ? 'At least 6 characters' : 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter a password.';
                    }
                    if (_isSignUp && val.length < 6) {
                      return 'Password must contain at least 6 characters.';
                    }
                    return null;
                  },
                ),

                // Password Strength Indicator (Sign Up only)
                if (_isSignUp && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: passwordStrength / 4.0,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(passwordStrength)),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        _getStrengthLabel(passwordStrength),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStrengthColor(passwordStrength),
                        ),
                      ),
                    ],
                  ),
                ],

                // Confirm Password (Sign Up only)
                if (_isSignUp) ...[
                  const SizedBox(height: AppDimensions.space16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
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
                ],

                // Forgot Password Link (Sign In only)
                if (!_isSignUp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.caption.copyWith(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                ],

                // Terms Checkbox (Sign Up only)
                if (_isSignUp) ...[
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                        activeColor: AppColors.primaryBlue,
                      ),
                      Expanded(
                        child: Text(
                          'I agree to Rexam\'s Terms of Service and Privacy Policy.',
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppDimensions.space16),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Or Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                      child: Text('OR', style: AppTypography.caption),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: AppDimensions.space20),

                // Google Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        _isSignUp ? 'Register with Google' : 'Sign in with Google',
                        style: AppTypography.button.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Switch Between Sign In and Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
                      style: AppTypography.caption,
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
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
