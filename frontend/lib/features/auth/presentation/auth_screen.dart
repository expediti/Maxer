import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _localError = null;
    });

    final notifier = ref.read(authProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await notifier.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    } else {
      success = await notifier.signInWithEmail(
        _emailController.text,
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
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).signInAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/discover');
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedDefault,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Reset Password', style: AppTypography.screenTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address. An official reset instruction link will be dispatched.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppDimensions.space16),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(authProvider.notifier).sendPasswordReset(resetEmailController.text);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Password reset instructions sent.' : 'Unable to send reset instructions.'),
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final displayedError = _localError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Header
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppDimensions.roundedSmall,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Text('REXAM', style: AppTypography.brandTitle.copyWith(fontSize: 18, letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Title & Mode Switcher
                  Text(
                    _isSignUp ? 'Create candidate account' : 'Sign in to Rexam',
                    style: AppTypography.screenTitle.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    _isSignUp
                        ? 'Set up your eligibility profile to discover qualified opportunities.'
                        : 'Access verified opportunities, track applications and deadline alerts.',
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Error Display
                  if (displayedError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: AppDimensions.roundedSmall,
                        border: Border.all(color: AppColors.error.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: Text(
                              displayedError,
                              style: AppTypography.caption.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                  ],

                  // Form Fields
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name (as per 10th / Matriculation Certificate)',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Full name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot password?',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Google Sign-in
                  OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 24, color: AppColors.textMain),
                    label: const Text('Continue with Google'),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final ok = await ref.read(authProvider.notifier).signInWithGoogle();
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                      if (ok) context.go('/discover');
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? 'Already registered?' : 'New candidate?',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _localError = null;
                          });
                        },
                        child: Text(_isSignUp ? 'Sign in' : 'Create an account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Guest Browsing Option
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _continueAsGuest,
                      child: Text(
                        'Browse as Guest (Explore without signing in)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
