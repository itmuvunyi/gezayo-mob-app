import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/phone_helper.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/simulated_map_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../customer/domain/delivery_model.dart';
import '../../presentation/delivery_notifier.dart';

class LiveTrackingScreen extends ConsumerWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryNotifierProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final theme = Theme.of(context);
    final activeDeliveryId = deliveryState.activeDelivery?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Track Order',
            style: AppTypography.headlineMedium(
                color: theme.colorScheme.onSurface)),
        centerTitle: true,
      ),
      body: StreamBuilder<DeliveryModel?>(
        stream: activeDeliveryId.isNotEmpty
            ? firestoreService.getDeliveryStream(activeDeliveryId)
            : Stream.value(deliveryState.activeDelivery),
        builder: (context, snapshot) {

          final delivery = snapshot.data ?? deliveryState.activeDelivery;


          if (delivery == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Order to Track',
                      style: AppTypography.headlineMedium(
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not have any active delivery request at the moment.\nPost a new delivery to track your rider live here!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.go('/customer'),
                      icon: const Icon(Icons.add_location_alt,
                          color: Colors.white),
                      label: const Text(
                        'Post Delivery Request',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final isSearching = delivery.status == DeliveryStatus.searching;
          final isAssigned = delivery.status == DeliveryStatus.assigned;
          final isPickedUp = delivery.status == DeliveryStatus.pickedUp;
          final isDelivered = delivery.status == DeliveryStatus.delivered;

          final riderUid = delivery.assignedRiderUid ?? '';


          return FutureBuilder<Map<String, dynamic>?>(
            future: riderUid.isNotEmpty
                ? firestoreService.getRiderDetails(riderUid)
                : Future.value(null),
            builder: (context, riderSnap) {
              final riderMap = riderSnap.data;
              final riderName = riderMap?['fullName'] ??
                  riderMap?['name'] ??
                  (delivery.assignedRiderName != null &&
                          delivery.assignedRiderName!.isNotEmpty
                      ? delivery.assignedRiderName!
                      : (riderUid.isNotEmpty
                          ? 'Rider #${riderUid.substring(0, riderUid.length > 8 ? 8 : riderUid.length)}'
                          : 'Rider Accepted'));

              final riderPhone = riderMap?['phoneNumber'] ??
                  riderMap?['phone'] ??
                  (delivery.assignedRiderPhone != null &&
                          delivery.assignedRiderPhone!.isNotEmpty
                      ? delivery.assignedRiderPhone!
                      : '');

              final riderRating = (riderMap?['rating'] ??
                      delivery.assignedRiderRating)
                  .toDouble();


              final vehicleDetails = riderMap?['vehicleType'] ??
                  riderMap?['vehicle'] ??
                  'GezaYo Verified Rider';

              // Dynamic Estimated Arrival computation
              String etaHeader = 'ESTIMATED ARRIVAL';
              String etaMins = '12';
              String statusSubtext = 'Rider navigating to pickup point';

              if (isSearching) {
                etaHeader = 'SEARCHING FOR RIDER';
                etaMins = '--';
                statusSubtext =
                    'Connecting with nearby available riders in Kigali...';
              } else if (isAssigned) {
                etaHeader = 'ARRIVING AT PICKUP';
                etaMins = '5';
                statusSubtext = '$riderName is navigating to pickup location.';
              } else if (isPickedUp) {
                etaHeader = 'EN ROUTE TO DROPOFF';
                etaMins = '12';
                statusSubtext =
                    'Package picked up! $riderName is on the way to dropoff.';
              } else if (isDelivered) {
                etaHeader = 'PACKAGE DELIVERED';
                etaMins = '0';
                statusSubtext =
                    '$riderName completed delivery. Please confirm receipt below!';
              }

              return Stack(
                children: [
                  // Animated Live GPS Map
                  const Positioned.fill(
                    child: SimulatedMapWidget(
                      showRoute: true,
                      isLiveMoving: true,
                    ),
                  ),

                  // Floating ESTIMATED ARRIVAL Top Header Card
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    etaHeader,
                                    style: AppTypography.labelMedium(
                                        color: isDelivered
                                            ? AppColors.statusSuccess
                                            : AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        etaMins,
                                        style: AppTypography.displayMedium(
                                            color: theme.colorScheme.onSurface),
                                      ),
                                      const SizedBox(width: 4),
                                      if (!isSearching)
                                        Text('mins',
                                            style: AppTypography.titleLarge(
                                                color: theme
                                                    .colorScheme.onSurface)),
                                    ],
                                  ),
                                ],
                              ),
                              if (isDelivered)
                                const StatusBadge(
                                  text: 'Delivered',
                                  backgroundColor: AppColors.statusSuccessBg,
                                  textColor: AppColors.statusSuccess,
                                )
                              else if (isPickedUp)
                                StatusBadge.onTheWay()
                              else if (isAssigned)
                                const StatusBadge(
                                  text: 'Assigned',
                                  backgroundColor: AppColors.primaryMint,
                                  textColor: AppColors.primary,
                                )
                              else
                                StatusBadge.searching(),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Dynamic Status Explanation Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDelivered
                                  ? AppColors.statusSuccessBg
                                  : (isSearching
                                      ? AppColors.parcelBg
                                      : AppColors.primaryMint),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDelivered
                                      ? Icons.check_circle_outline
                                      : (isSearching
                                          ? Icons.search
                                          : Icons.directions_bike),
                                  size: 16,
                                  color: isDelivered
                                      ? AppColors.statusSuccess
                                      : (isSearching
                                          ? AppColors.accentOrange
                                          : AppColors.primary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    statusSubtext,
                                    style: AppTypography.bodySmall(
                                      color: isDelivered
                                          ? AppColors.statusSuccess
                                          : (isSearching
                                              ? AppColors.accentOrange
                                              : AppColors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Horizontal 4-Step Stepper (Dynamic from Firestore)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StepItem(
                                title: 'Ordered',
                                isDone: !isSearching,
                                isActive: isSearching,
                              ),
                              _StepItem(
                                title: 'Picked up',
                                isDone: isPickedUp || isDelivered,
                                isActive: isAssigned,
                              ),
                              _StepItem(
                                title: 'On the way',
                                isDone: isDelivered,
                                isActive: isPickedUp,
                              ),
                              _StepItem(
                                title: 'Confirm',
                                isDone: false,
                                isActive: isDelivered,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Rider Profile & Delivery Confirmation Overlay
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 12),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSearching) ...[
                            // Searching for Rider Card View
                            Row(
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Broadcasting Order to Riders...',
                                        style: AppTypography.titleMedium(
                                            color: theme.colorScheme.onSurface),
                                      ),
                                      Text(
                                        'A nearby rider will accept in seconds',
                                        style: AppTypography.bodySmall(
                                            color: theme
                                                .colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Real Firestore RIDER PROFILE CARD
                            Row(
                              children: [
                                // Rider Photo Avatar with Verified Icon
                                const Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.primaryMint,
                                      child: Icon(Icons.person,
                                          size: 36, color: AppColors.primary),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(Icons.verified,
                                          color: AppColors.primary, size: 18),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),

                                // Rider Name, Vehicle & Rating from Firestore
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        riderName,
                                        style: AppTypography.titleLarge(
                                            color: theme.colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        vehicleDetails,
                                        style: AppTypography.bodySmall(
                                            color: theme
                                                .colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$riderRating',
                                            style: AppTypography.bodySmall(
                                                color:
                                                    AppColors.accentOrangeDark),
                                          ),
                                          if (riderPhone.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text('•',
                                                style: AppTypography.bodySmall(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant)),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.phone,
                                                size: 12,
                                                color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                riderPhone,
                                                style: AppTypography.bodySmall(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Direct Phone Call Button
                                if (riderPhone.isNotEmpty)
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    icon: const Icon(Icons.phone,
                                        color: Colors.white),
                                    onPressed: () {
                                      PhoneHelper.makePhoneCall(
                                          context, riderPhone);
                                    },
                                  ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Dynamic Action Button (Confirm Delivery & Complete)
                          if (isDelivered) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.statusSuccessBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.statusSuccess, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Rider completed delivery! Please confirm below.',
                                      style: AppTypography.bodySmall(
                                          color: AppColors.statusSuccess),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                key: const ValueKey('confirm_delivery_complete_btn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusSuccess,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final activeDelivery =
                                      deliveryState.activeDelivery;
                                  if (activeDelivery != null) {
                                    await ref
                                        .read(deliveryNotifierProvider.notifier)
                                        .clearActiveDelivery(activeDelivery.id);
                                  }
                                  if (context.mounted) {
                                    context.go('/customer');
                                  }
                                },
                                child: Text('Confirm Delivery & Complete',
                                    style: AppTypography.labelLarge(
                                        color: Colors.white)),
                              ),
                            ),
                          ] else if (!isSearching) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () =>
                                    context.push('/order-completion'),
                                child: Text(
                                  isPickedUp
                                      ? 'Order In Transit...'
                                      : 'Track Order Details',
                                  style: AppTypography.labelLarge(
                                      color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
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

class _StepItem extends StatelessWidget {
  final String title;
  final bool isDone;
  final bool isActive;

  const _StepItem({
    required this.title,
    this.isDone = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.statusSuccess
                : (isActive ? AppColors.primary : AppColors.cardBorder),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : (isActive
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTypography.bodySmall(
            color: isDone || isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
