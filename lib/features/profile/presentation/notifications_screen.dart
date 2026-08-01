import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';


class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';
  final Set<String> _readNotifIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notifications',
          style: AppTypography.headlineMedium(
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).markAllAsRead();
              setState(() {
                _readNotifIds.add('ALL');
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },

            child: Text(
              'Mark as Read',
              style: AppTypography.labelMedium(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: ['All', 'Deliveries', 'Transactions', 'System'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Notifications Stream List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  );
                }

                final rawList = snapshot.data ?? [];

                // Filter logic
                final notificationsData = rawList.where((n) {
                  if (_selectedFilter == 'Deliveries') {
                    return n['type'] == 'delivery';
                  } else if (_selectedFilter == 'Transactions') {
                    return n['type'] == 'transaction';
                  } else if (_selectedFilter == 'System') {
                    return n['type'] == 'system';
                  }
                  return true;
                }).toList();

                if (notificationsData.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off_outlined,
                              size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No Notifications Yet',
                            style: AppTypography.headlineMedium(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Real-time updates regarding your delivery orders and transactions will appear here.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: notificationsData.length,
                  itemBuilder: (context, index) {
                    final data = notificationsData[index];
                    final notifId = data['id'] ?? 'notif_$index';
                    final isMarkedRead = _readNotifIds.contains('ALL') || _readNotifIds.contains(notifId);
                    final isUnread = (data['isUnread'] ?? false) && !isMarkedRead;

                    return NotificationTile(
                      key: ValueKey('notif_tile_$notifId'),
                      item: NotificationItem(
                        id: notifId,
                        title: data['title'] ?? 'Notification',
                        subtitle: data['subtitle'] ?? '',
                        timeText: data['timeText'] ?? 'Just now',
                        isUnread: isUnread,
                        type: data['type'] ?? 'delivery',
                        route: data['route'] ?? '/customer',
                      ),
                      onTap: () {
                        setState(() {
                          _readNotifIds.add(notifId);
                        });
                        final route = data['route'] as String?;
                        if (route != null && route.isNotEmpty) {
                          context.push(route);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String timeText;
  final bool isUnread;
  final String type;
  final String route;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.isUnread,
    required this.type,
    required this.route,
  });
}

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData typeIcon = Icons.notifications_active;
    Color iconBg = AppColors.parcelBg;
    Color iconColor = AppColors.primary;

    if (item.type == 'transaction') {
      typeIcon = Icons.account_balance_wallet_outlined;
      iconBg = AppColors.statusSuccessBg;
      iconColor = AppColors.statusSuccess;
    } else if (item.type == 'system') {
      typeIcon = Icons.info_outline;
      iconBg = AppColors.primaryMint;
      iconColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isUnread
            ? AppColors.primaryMint.withValues(alpha: 0.5)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isUnread
              ? AppColors.primary
              : theme.dividerColor.withValues(alpha: 0.3),
          width: item.isUnread ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTypography.titleMedium(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (item.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: AppTypography.bodyMedium(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.timeText,
                            style: AppTypography.bodySmall(
                              color: AppColors.textMuted,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'View',
                                style: AppTypography.bodySmall(
                                  color: AppColors.primary,
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 14, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
