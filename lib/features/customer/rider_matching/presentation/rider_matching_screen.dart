import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/simulated_map_widget.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/delivery_model.dart';
import '../../presentation/delivery_notifier.dart';

class RiderMatchingScreen extends ConsumerWidget {
  const RiderMatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryNotifierProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final theme = Theme.of(context);
    final delivery = deliveryState.activeDelivery;

    // Listen to delivery status — when rider accepts, automatically go to live tracking
    ref.listen<DeliveryState>(deliveryNotifierProvider, (previous, next) {
      if (next.activeDelivery?.status == DeliveryStatus.assigned) {
        context.push('/live-tracking');
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        showBackButton: true,
        title: 'GezaYo',
      ),
      body: Stack(
        children: [
          // Upper Radar Map Canvas with real-time online riders
          Positioned.fill(
            child: StreamBuilder<List<UserModel>>(
              stream: firestoreService.getOnlineRidersStream(),
              builder: (context, snapshot) {
                final onlineRiders = snapshot.data ?? [];
                final riderCoords = onlineRiders
                    .map((r) => LatLng(r.latitude, r.longitude))
                    .toList();

                return SimulatedMapWidget(
                  riderLocations: riderCoords,
                  centerLabel: onlineRiders.isEmpty
                      ? 'Looking for nearby riders...'
                      : '${onlineRiders.length} rider(s) online',
                );
              },
            ),
          ),

          // Bottom Sheet Content overlay
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Handle Bar Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Searching Indicator Animation & Status
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySubtle,
                              shape: BoxShape.circle,
                            ),

                            child: const CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            delivery?.status == DeliveryStatus.assigned
                                ? 'Rider Accepted Your Job!'
                                : 'Searching for Available Riders...',
                            style: AppTypography.headlineMedium(
                                color: theme.colorScheme.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            delivery?.status == DeliveryStatus.assigned
                                ? 'Rider ${delivery?.assignedRiderName ?? ''} is on their way'
                                : 'Your job post is live. Nearby riders will be notified to accept.',
                            style: AppTypography.bodyMedium(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Order Details Summary Card
                    if (delivery != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('YOUR OFFERED PRICE',
                                    style: AppTypography.labelMedium(
                                        color: AppColors.primary)),
                                Text(
                                  '${delivery.estimatedFareRwf.toStringAsFixed(0)} RWF',
                                  style: AppTypography.headlineMedium(
                                      color: theme.colorScheme.onSurface),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.radio_button_checked,
                                    color: AppColors.statusSuccess, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Pick: ${delivery.pickupAddress}',
                                      style: AppTypography.bodySmall(
                                          color: theme.colorScheme.onSurface),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.accentOrange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Drop: ${delivery.dropoffAddress}',
                                      style: AppTypography.bodySmall(
                                          color: theme.colorScheme.onSurface),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/customer');
          if (index == 2) context.push('/profile');
        },
      ),
    );
  }
}
