import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../customer/presentation/delivery_notifier.dart';

final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<String> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_storage.getThemeMode());

  void setTheme(String mode) {
    _storage.setThemeMode(mode);
    state = mode;
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(authNotifierProvider.notifier);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.statusError),
            const SizedBox(width: 8),
            Text(
              'Confirm Logout',
              style: AppTypography.headlineMedium(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your GezaYo account?',
          style: AppTypography.bodyMedium(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(100, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              minimumSize: const Size(110, 44),
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              ref.read(deliveryNotifierProvider.notifier).resetState();
              await notifier.logout();
              if (context.mounted) context.go('/auth');
            },
            child: Text(
              'Logout',
              style: AppTypography.titleMedium(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.read(themeModeNotifierProvider);

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Theme Mode',
          style: AppTypography.headlineMedium(
            color: theme.colorScheme.onSurface,
          ),
        ),
        children: [
          RadioListTile<String>(
            activeColor: theme.colorScheme.primary,
            title: Text(
              'Light Mode',
              style: AppTypography.titleMedium(
                color: theme.colorScheme.onSurface,
              ),
            ),
            value: 'light',
            // ignore: deprecated_member_use
            groupValue: currentTheme,
            // ignore: deprecated_member_use
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeNotifierProvider.notifier).setTheme(val);
                Navigator.of(ctx).pop();
              }
            },
          ),
          RadioListTile<String>(
            activeColor: theme.colorScheme.primary,
            title: Text(
              'Dark Mode',
              style: AppTypography.titleMedium(
                color: theme.colorScheme.onSurface,
              ),
            ),
            value: 'dark',
            // ignore: deprecated_member_use
            groupValue: currentTheme,
            // ignore: deprecated_member_use
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeNotifierProvider.notifier).setTheme(val);
                Navigator.of(ctx).pop();
              }
            },
          ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeNotifierProvider);


    return Scaffold(
      appBar: CustomAppBar(
        title: 'GezaYo',
        userName: user?.fullName ?? 'User',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Avatar with verified badge
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.cardColor,
                      child: Icon(Icons.check_circle,
                          color: theme.colorScheme.primary, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              user?.fullName ?? 'Account User',
              style: AppTypography.headlineMedium(
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: AppTypography.bodySmall(
                  color: theme.colorScheme.onSurfaceVariant),
            ),

            const SizedBox(height: 24),

            // Section Header: PREFERENCES
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PREFERENCES',
                style: AppTypography.labelMedium(color: AppColors.textMuted),
              ),
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
                  // Theme Mode Setting
                  ListTile(
                    leading: Icon(Icons.palette_outlined,
                        color: theme.colorScheme.primary),
                    title: Text(
                      'Theme Mode',
                      style: AppTypography.titleMedium(
                          color: theme.colorScheme.onSurface),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeMode == 'dark' ? 'Dark' : 'Light',
                          style: AppTypography.bodyMedium(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textMuted),
                      ],
                    ),
                    onTap: () => _showThemeDialog(context, ref),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.notifications_none,
                        color: theme.colorScheme.primary),
                    title: Text(
                      'Notifications',
                      style: AppTypography.titleMedium(
                          color: theme.colorScheme.onSurface),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading:
                        Icon(Icons.security, color: theme.colorScheme.primary),
                    title: Text(
                      'Security',
                      style: AppTypography.titleMedium(
                          color: theme.colorScheme.onSurface),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () => context.push('/settings/security'),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.help_outline,
                        color: theme.colorScheme.primary),
                    title: Text(
                      'Help Center',
                      style: AppTypography.titleMedium(
                          color: theme.colorScheme.onSurface),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () => context.push('/help'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusErrorBg,
                  foregroundColor: AppColors.statusError,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _showLogoutConfirmation(context, ref),
                icon: const Icon(Icons.logout, color: AppColors.statusError),
                label: Text(
                  'Logout',
                  style: AppTypography.labelLarge(color: AppColors.statusError),
                ),
              ),
            ),


            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            if (user?.isRider == true) {
              context.go('/rider');
            } else {
              context.go('/customer');
            }
          }
          if (index == 1) {
            if (user?.isRider == true) {
              context.push('/earnings');
            } else {
              context.push('/live-tracking');
            }
          }
        },
      ),
    );
  }
}
