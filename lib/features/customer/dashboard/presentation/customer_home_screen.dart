import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/simulated_map_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../domain/delivery_model.dart';
import '../../presentation/delivery_notifier.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final user = authState.user;
    final displayName = user?.fullName.split(' ').first ?? 'Customer';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'GezaYo',
        userName: displayName,
        onNotificationTap: () => context.push('/notifications'),
        onAvatarTap: () => context.push('/profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2x2 Service Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _ServiceCard(
                  title: 'Food Delivery',
                  icon: Icons.restaurant,
                  bgColor: AppColors.foodBg,
                  iconColor: AppColors.foodIcon,
                  onTap: () => context.push('/create-delivery?type=Food'),
                ),
                _ServiceCard(
                  title: 'Groceries',
                  icon: Icons.shopping_cart,
                  bgColor: AppColors.groceryBg,
                  iconColor: AppColors.groceryIcon,
                  onTap: () =>
                      context.push('/create-delivery?type=Grocery'),
                ),
                _ServiceCard(
                  title: 'Parcels',
                  icon: Icons.inventory_2,
                  bgColor: AppColors.parcelBg,
                  iconColor: AppColors.parcelIcon,
                  onTap: () => context.push('/create-delivery?type=Parcel'),
                ),
                _ServiceCard(
                  title: 'Errands',
                  icon: Icons.check_circle_outline,
                  bgColor: AppColors.errandsBg,
                  iconColor: AppColors.errandsIcon,
                  onTap: () => context.push('/create-delivery?type=Other'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Header: My Posted Jobs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Posted Jobs',
                  style: AppTypography.headlineMedium(
                      color: theme.colorScheme.onSurface),
                ),
                Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),

            const SizedBox(height: 12),

            // Stream of Posted Jobs by this customer
            StreamBuilder<List<DeliveryModel>>(
              stream: firestoreService.getCustomerDeliveriesStream(
                user?.phoneNumber,
                user?.uid,
              ),
              builder: (context, snapshot) {
                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No posted jobs yet. Select a service above to post a delivery!',
                            style: AppTypography.bodySmall(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: jobs.take(5).map((job) {
                    return _PostedJobCard(
                      key: ValueKey('posted_job_${job.id}'),
                      job: job,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section Header: Nearby Riders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Riders',
                  style: AppTypography.headlineMedium(
                      color: theme.colorScheme.onSurface),
                ),
                StatusBadge.live(),
              ],
            ),

            const SizedBox(height: 12),

            // Map Container listening to real-time online riders
            SizedBox(
              height: 240,
              child: StreamBuilder<List<UserModel>>(
                stream: firestoreService.getOnlineRidersStream(),
                builder: (context, snapshot) {
                  final onlineRiders = snapshot.data ?? [];
                  final riderCoords = onlineRiders
                      .map((r) => LatLng(r.latitude, r.longitude))
                      .toList();

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SimulatedMapWidget(
                      riderLocations: riderCoords,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/live-tracking');
          if (index == 2) context.push('/profile');
        },
      ),
    );
  }
}

class _PostedJobCard extends ConsumerWidget {
  final DeliveryModel job;

  const _PostedJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Widget statusBadge;
    switch (job.status) {
      case DeliveryStatus.searching:
        statusBadge = const StatusBadge(
          text: 'Searching',
          backgroundColor: AppColors.statusErrorBg,
          textColor: AppColors.accentOrange,
        );
        break;
      case DeliveryStatus.assigned:
        statusBadge = const StatusBadge(
          text: 'Rider Assigned',
          backgroundColor: AppColors.primaryMint,
          textColor: AppColors.primary,
        );
        break;
      case DeliveryStatus.pickedUp:
        statusBadge = StatusBadge.onTheWay();
        break;
      case DeliveryStatus.delivered:
        statusBadge = const StatusBadge(
          text: 'Delivered',
          backgroundColor: AppColors.statusSuccessBg,
          textColor: AppColors.statusSuccess,
        );
        break;
      case DeliveryStatus.completed:
        statusBadge = StatusBadge.completed();
        break;
      default:
        statusBadge = const StatusBadge(
          text: 'Pending',
          backgroundColor: AppColors.primaryMint,
          textColor: AppColors.primary,
        );
    }

    IconData packageIcon;
    switch (job.packageType.toLowerCase()) {
      case 'food':
        packageIcon = Icons.restaurant;
        break;
      case 'grocery':
        packageIcon = Icons.shopping_cart;
        break;
      case 'parcel':
        packageIcon = Icons.inventory_2;
        break;
      default:
        packageIcon = Icons.local_shipping;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('job_inkwell_${job.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(deliveryNotifierProvider.notifier).setActiveDelivery(job);
            if (job.status == DeliveryStatus.searching) {
              context.push('/rider-matching');
            } else if (job.status == DeliveryStatus.delivered ||
                job.status == DeliveryStatus.completed) {
              context.push('/order-completion');
            } else {
              context.push('/live-tracking');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Job ID, Package Type, Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(packageIcon, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${job.packageType} #${job.id}',
                          style: AppTypography.titleLarge(
                              color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                    statusBadge,
                  ],
                ),

                const Divider(height: 20),

                // Route: Pickup -> Dropoff
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        color: AppColors.statusSuccess, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.pickupAddress,
                        style: AppTypography.bodySmall(
                            color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.accentOrange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.dropoffAddress,
                        style: AppTypography.bodySmall(
                            color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom Row: Price & Action CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${job.estimatedFareRwf.toStringAsFixed(0)} RWF',
                      style: AppTypography.titleMedium(color: AppColors.primary),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: AppTypography.labelLarge(color: AppColors.primary),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 18),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('service_card_$title'),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('service_inkwell_$title'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: iconColor),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTypography.titleLarge(color: iconColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
