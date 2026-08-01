import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../auth/domain/user_model.dart';
import '../../../customer/domain/delivery_model.dart';
import '../../presentation/delivery_notifier.dart';

class OrderCompletionScreen extends ConsumerStatefulWidget {
  final String? deliveryId;

  const OrderCompletionScreen({super.key, this.deliveryId});

  @override
  ConsumerState<OrderCompletionScreen> createState() =>
      _OrderCompletionScreenState();
}

class _OrderCompletionScreenState extends ConsumerState<OrderCompletionScreen> {
  double _selectedTip = 1000;
  int _userRating = 5;
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {

    final deliveryState = ref.watch(deliveryNotifierProvider);
    final notifier = ref.read(deliveryNotifierProvider.notifier);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final theme = Theme.of(context);
    final targetDeliveryId =
        widget.deliveryId ?? deliveryState.activeDelivery?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'GezaYo',
      ),
      body: StreamBuilder<DeliveryModel?>(
        stream: targetDeliveryId.isNotEmpty
            ? firestoreService.getDeliveryStream(targetDeliveryId)
            : Stream.value(deliveryState.activeDelivery),
        builder: (context, snapshot) {
          final delivery = snapshot.data ?? deliveryState.activeDelivery;

          final fareFormatted = (delivery?.estimatedFareRwf ?? 2500)
              .toStringAsFixed(0)
              .replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              );

          final totalFormatted =
              (delivery?.totalPaid ?? 2500).toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  );

          final riderUid = delivery?.assignedRiderUid ?? '';

          return FutureBuilder<UserModel?>(
            future: riderUid.isNotEmpty
                ? firestoreService.getUser(riderUid)
                : Future.value(null),
            builder: (context, riderSnap) {
              final riderUser = riderSnap.data;
              final riderName = (riderUser?.fullName != null &&
                      riderUser!.fullName.isNotEmpty)
                  ? riderUser.fullName
                  : ((delivery?.assignedRiderName != null &&
                          delivery!.assignedRiderName!.isNotEmpty)
                      ? delivery.assignedRiderName!
                      : 'Your Rider');

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Column(
                  children: [

                        // Celebration Checkmark Circle
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: AppColors.statusSuccess,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x3310B981),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check,
                              size: 48, color: Colors.white),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Order Details & Receipt',
                          style: AppTypography.displayMedium(
                              color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery?.status == DeliveryStatus.delivered
                              ? 'Package delivered successfully!'
                              : 'Order is active & safely in transit.',
                          style: AppTypography.bodyMedium(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),

                        const SizedBox(height: 24),

                        // Order Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long,
                                      color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text('Order Summary',
                                      style: AppTypography.titleLarge(
                                          color: theme.colorScheme.onSurface)),
                                ],
                              ),
                              const Divider(height: 24),
                              _SummaryRow(
                                title:
                                    'Package: ${delivery?.packageType ?? 'Parcel'}',
                                amount: delivery?.weightClass ?? 'Light',

                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                title: 'Pickup',
                                amount: delivery?.pickupAddress ??
                                    'Kigali City Center',
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                title: 'Drop-off',
                                amount: delivery?.dropoffAddress ??
                                    'Remera, Kigali',
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                title: 'Offered Delivery Fare',
                                amount: '$fareFormatted RWF',
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Fare Paid',
                                      style: AppTypography.headlineMedium(
                                          color: theme.colorScheme.onSurface)),
                                  Text(
                                    '$totalFormatted RWF',
                                    style: AppTypography.headlineLarge(
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 2-Column Metrics (Package Type & Status)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.parcelBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text('PACKAGE TYPE',
                                        style: AppTypography.bodySmall(
                                            color: AppColors.primary)),
                                    Text(delivery?.packageType ?? 'Parcel',
                                        style: AppTypography.titleMedium(
                                            color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMint,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.local_shipping_outlined,
                                        color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text('STATUS',
                                        style: AppTypography.bodySmall(
                                            color: AppColors.primary)),
                                    Text(
                                      delivery?.status.name.toUpperCase() ??
                                          'TRANSIT',
                                      style: AppTypography.titleMedium(
                                          color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Rider Rating Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primaryMint,
                                child: Icon(Icons.person,
                                    size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              Text('Rate $riderName',
                                  style: AppTypography.titleLarge(
                                      color: theme.colorScheme.onSurface)),
                              Text('How was your delivery service?',
                                  style: AppTypography.bodyMedium(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 12),
                              RatingStars(
                                rating: _userRating,
                                onRatingChanged: (stars) {
                                  setState(() => _userRating = stars);
                                  notifier.setRating(stars);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tip Your Rider Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primaryLight, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pan_tool_alt_outlined,
                                      color: AppColors.accentOrange),
                                  const SizedBox(width: 8),
                                  Text('Tip your rider',
                                      style: AppTypography.titleLarge(
                                          color: theme.colorScheme.onSurface)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Show appreciation for fast delivery!',
                                  style: AppTypography.bodyMedium(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _TipPill(
                                    amountText: '500 RWF',
                                    isSelected: _selectedTip == 500,
                                    onTap: () =>
                                        setState(() => _selectedTip = 500),
                                  ),
                                  _TipPill(
                                    amountText: '1,000 RWF',
                                    isSelected: _selectedTip == 1000,
                                    onTap: () =>
                                        setState(() => _selectedTip = 1000),
                                  ),
                                  _TipPill(
                                    amountText: '2,000 RWF',
                                    isSelected: _selectedTip == 2000,
                                    onTap: () =>
                                        setState(() => _selectedTip = 2000),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.smartphone,
                                              color: AppColors.statusSuccess),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Mobile Money Pay',
                                                    style:
                                                        AppTypography.titleMedium(
                                                            color: theme.colorScheme
                                                                .onSurface)),
                                                Text('Fast & Secure',
                                                    style: AppTypography.bodySmall(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        notifier.addTip(_selectedTip);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Added ${_selectedTip.toStringAsFixed(0)} RWF tip via MoMo!')),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Add Tip',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ),

                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Button (Confirm Delivery or Return to Dashboard)
                        if (delivery?.status == DeliveryStatus.delivered)
                          PrimaryButton(
                            text: 'Confirm Delivery & Complete',
                            icon: Icons.check_circle_outline,
                            backgroundColor: AppColors.statusSuccess,
                            isLoading: _isCompleting,
                            onPressed: _isCompleting
                                ? () {}
                                : () async {
                                    setState(() => _isCompleting = true);
                                    try {
                                      final activeId = delivery?.id ??
                                          deliveryState.activeDelivery?.id;
                                      if (activeId != null &&
                                          activeId.isNotEmpty) {
                                        await ref
                                            .read(
                                                deliveryNotifierProvider.notifier)
                                            .clearActiveDelivery(activeId);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Delivery confirmed! Payment released to rider.'),
                                            backgroundColor:
                                                AppColors.statusSuccess,
                                          ),
                                        );
                                        context.go('/customer');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error confirming delivery: $e')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isCompleting = false);
                                      }
                                    }
                                  },
                          )

                        else if (delivery?.status == DeliveryStatus.completed)
                          PrimaryButton(
                            text: 'Back to Customer Dashboard',
                            icon: Icons.home,
                            backgroundColor: AppColors.primary,
                            onPressed: () {
                              context.go('/customer');
                            },
                          )
                        else
                          PrimaryButton(
                            text: 'Back to Live Map',
                            icon: Icons.map,
                            onPressed: () {
                              context.go('/live-tracking');
                            },
                          ),

                      ],
                    ),
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

class _SummaryRow extends StatelessWidget {
  final String title;
  final String amount;

  const _SummaryRow({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodyMedium(
                color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(amount,
            style:
                AppTypography.titleMedium(color: theme.colorScheme.onSurface)),
      ],
    );
  }
}

class _TipPill extends StatelessWidget {
  final String amountText;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipPill({
    required this.amountText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('tip_pill_$amountText'),
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMint : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          amountText,
          style: AppTypography.titleMedium(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
