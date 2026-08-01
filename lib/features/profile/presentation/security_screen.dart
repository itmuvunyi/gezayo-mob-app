import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/presentation/auth_notifier.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _rememberLogin = true;

  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Change Password',
              style: AppTypography.headlineMedium(
                color: theme.colorScheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Current Password',
                    hintText: '••••••••',
                    obscureText: obscureCurrent,
                    controller: currentPassController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'New Password',
                    hintText: '••••••••',
                    obscureText: obscureNew,
                    controller: newPassController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setDialogState(
                          () => obscureNew = !obscureNew),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Confirm New Password',
                    hintText: '••••••••',
                    obscureText: obscureConfirm,
                    controller: confirmPassController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: AppTypography.bodySmall(color: AppColors.statusError),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 44),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.titleMedium(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 44),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final currentPass = currentPassController.text.trim();
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();

                        if (currentPass.isEmpty) {
                          setDialogState(() => dialogError = 'Please enter your current password.');
                          return;
                        }
                        if (newPass.length < 6) {
                          setDialogState(() => dialogError = 'New password must be at least 6 characters.');
                          return;
                        }
                        if (newPass != confirmPass) {
                          setDialogState(() => dialogError = 'New passwords do not match.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .changePassword(currentPass, newPass);

                        if (context.mounted && ctx.mounted) {
                          if (success) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully!'),
                                backgroundColor: AppColors.statusSuccess,
                              ),
                            );
                          } else {

                            final authErr = ref.read(authNotifierProvider).errorMessage;
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = authErr ?? 'Failed to update password.';
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }


  void _showDeleteAccountDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.statusError),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: AppTypography.headlineMedium(color: AppColors.statusError),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your GezaYo account? This action is non-reversible and all your data will be permanently erased.',
          style: AppTypography.bodyMedium(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(90, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.titleMedium(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(150, 44),
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).deleteAccount();
              if (mounted) context.go('/auth');
            },

            child: const Text('Delete Permanently',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Security & Privacy',
          style: AppTypography.headlineMedium(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Login & Authentication Settings
            Text(
              'AUTHENTICATION SETTINGS',
              style: AppTypography.labelMedium(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline,
                        color: theme.colorScheme.primary),
                    title: Text(
                      'Change Password',
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Update your account password',
                      style: AppTypography.bodySmall(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: AppColors.primaryLight,
                    secondary: Icon(Icons.remember_me,
                        color: theme.colorScheme.primary),
                    title: Text(
                      'Remember Login State',
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Stay signed in automatically on startup',
                      style: AppTypography.bodySmall(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: _rememberLogin,
                    onChanged: (val) => setState(() => _rememberLogin = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active Sessions
            Text(
              'ACTIVE SESSIONS',
              style: AppTypography.labelMedium(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone,
                      color: AppColors.statusSuccess, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kigali Mobile Device (This Phone)',
                          style: AppTypography.titleMedium(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Active Now • Android App v1.0.0',
                          style: AppTypography.bodySmall(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Danger Zone Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusErrorBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.statusError.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DANGER ZONE',
                      style: AppTypography.labelMedium(
                          color: AppColors.statusError)),
                  const SizedBox(height: 6),
                  Text(
                    'Permanently remove your account and erase personal delivery history.',
                    style:
                        AppTypography.bodySmall(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'Delete Account',
                    backgroundColor: AppColors.statusError,
                    onPressed: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
