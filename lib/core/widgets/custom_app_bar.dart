import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String avatarUrl;
  final String userName;
  final bool showBackButton;
  final bool showNotification;
  final bool hasUnreadNotifications;
  final Widget? trailing;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const CustomAppBar({
    super.key,
    this.title = 'GezaYo',
    this.avatarUrl = '',
    this.userName = 'User',
    this.showBackButton = false,
    this.showNotification = true,
    this.hasUnreadNotifications = false,
    this.trailing,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifState = ref.watch(notificationNotifierProvider);
    final showBadge = hasUnreadNotifications || notifState.hasUnread;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
          ] else ...[
            GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: AppTypography.titleLarge(
                      color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style:
                AppTypography.headlineMedium(color: theme.colorScheme.primary),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (showNotification)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_outlined,
                      color: theme.colorScheme.onSurface, size: 26),
                  onPressed: onNotificationTap ??
                      () => context.push('/settings/notifications'),
                ),
                if (showBadge)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

