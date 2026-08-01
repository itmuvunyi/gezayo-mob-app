import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/auth_validator.dart';
import 'auth_notifier.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'customer'; // 'customer' or 'rider'

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _validateForm() {
    setState(() {
      _nameError = _isSignUp
          ? AuthValidator.validateFullName(_nameController.text)
          : null;
      _emailError = AuthValidator.validateEmail(_emailController.text);
      _passwordError = AuthValidator.validatePassword(_passwordController.text);
      _confirmPasswordError = _isSignUp
          ? AuthValidator.validateConfirmPassword(
              _passwordController.text, _confirmPasswordController.text)
          : null;
    });

    return _emailError == null &&
        _passwordError == null &&
        (_isSignUp
            ? (_nameError == null && _confirmPasswordError == null)
            : true);
  }

  Future<void> _handleAuth() async {
    if (!_validateForm()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    final sanitizedEmail = AuthValidator.sanitizeEmail(_emailController.text);
    final sanitizedName = AuthValidator.sanitizeName(_nameController.text);
    final phone = _phoneController.text.trim();

    bool success = false;

    if (_isSignUp) {
      success = await notifier.signUpWithEmail(
        sanitizedEmail,
        _passwordController.text,
        sanitizedName,
        _selectedRole,
        phone,
      );
    } else {
      success = await notifier.loginWithEmail(
        sanitizedEmail,
        _passwordController.text,
        role: _selectedRole,
      );
    }

    if (success && mounted) {
      final user = ref.read(authNotifierProvider).user;
      final role = user?.role ?? _selectedRole;
      if (role == 'rider') {
        context.go('/rider');
      } else {
        context.go('/customer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Top Header with Logo 
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/logo.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.bolt, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GezaYo',
                    style: AppTypography.headlineMedium(
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hero Banner Card
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF046A38), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pedal_bike,
                          size: 40, color: Colors.white),
                      const SizedBox(height: 6),
                      Text(
                        'Swift & Reliable Delivery in Rwanda',
                        style: AppTypography.titleLarge(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _isSignUp ? 'Create Your Account' : 'Welcome Back',
                style: AppTypography.displayMedium(
                    color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? 'Fill in your details below to register with GezaYo.'
                    : 'Sign in with your email and password to access your dashboard.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(
                    color: theme.colorScheme.onSurfaceVariant),
              ),

              const SizedBox(height: 20),

              // Sign In vs Sign Up Toggle Pill
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = false;
                            _nameError = null;
                            _emailError = null;
                            _passwordError = null;
                            _confirmPasswordError = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelLarge(
                              color: !_isSignUp
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = true;
                            _nameError = null;
                            _emailError = null;
                            _passwordError = null;
                            _confirmPasswordError = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Sign Up',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelLarge(
                              color: _isSignUp
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isSignUp) ...[
                AppTextField(
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  controller: _nameController,
                  errorText: _nameError,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Phone Number',
                  hintText: 'e.g. +250 788 123 456',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
              ],

              AppTextField(
                label: 'Email Address',
                hintText: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Password',
                hintText: 'Enter password',
                obscureText: _obscurePassword,
                controller: _passwordController,
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (_isSignUp) ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirm Password',
                  hintText: 'Re-enter password',
                  obscureText: _obscureConfirmPassword,
                  controller: _confirmPasswordController,
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 20),

                // Role Selector Switcher (Customer vs Rider) - ONLY ON SIGN UP BEFORE BUTTON
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = 'customer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer'
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Customer Account',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelLarge(
                                color: _selectedRole == 'customer'
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'rider'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'rider'
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Rider Account',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelLarge(
                                color: _selectedRole == 'rider'
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (authState.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.statusError.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.statusError, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: AppTypography.bodySmall(
                              color: AppColors.statusError),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              PrimaryButton(
                text: _isSignUp ? 'Create Account' : 'Sign In',
                icon: Icons.arrow_forward,
                isLoading: authState.isLoading,
                onPressed: _handleAuth,
              ),


              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style:
                          AppTypography.labelMedium(color: AppColors.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // Social Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .signInWithGoogle(role: _selectedRole);

                        if (!context.mounted) return;
                        if (success) {
                          final user = ref.read(authNotifierProvider).user;
                          final role = user?.role ?? _selectedRole;
                          if (role == 'rider') {
                            context.go('/rider');
                          } else {
                            context.go('/customer');
                          }
                        }
                      },
                      icon: const Icon(Icons.g_mobiledata,
                          size: 28, color: Colors.deepOrange),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'By registering, you agree to GezaYo\'s Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}