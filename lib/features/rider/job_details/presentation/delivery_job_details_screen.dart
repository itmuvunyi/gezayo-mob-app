import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/phone_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/simulated_map_widget.dart';
import '../../../auth/domain/user_model.dart';
import '../../../customer/domain/delivery_model.dart';
import '../../presentation/rider_notifier.dart';

class DeliveryJobDetailsScreen extends ConsumerWidget {
  const DeliveryJobDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderState = ref.watch(riderNotifierProvider);
    final notifier = ref.read(riderNotifierProvider.notifier);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final theme = Theme.of(context);
    final jobId = riderState.activeJobId ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () async {
            await notifier.cancelActiveJob();
            if (context.mounted) Navigator.of(context).maybePop();
          },
        ),
        title: Text('Job Details',
            style: AppTypography.headlineMedium(
                color: theme.colorScheme.onSurface)),
      ),
      body: StreamBuilder<DeliveryModel?>(
        stream: firestoreService.getDeliveryStream(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = snapshot.data;

          if (job == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_late_outlined,
                        size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('No Active Job Selected',
                        style: AppTypography.titleLarge(
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Text('Please select or accept a job from your dashboard.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.go('/rider'),
                      child: const Text('Back to Dashboard',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          final fareFormatted =
              job.estimatedFareRwf.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  );

          final defaultPhone =
              (job.customerPhone != null && job.customerPhone!.isNotEmpty)
                  ? job.customerPhone!
                  : '+250788123456';

          return FutureBuilder<UserModel?>(
            future: firestoreService.getUser(job.customerUid),
            builder: (context, userSnap) {
              final customerUser = userSnap.data;
              final customerPhone = (customerUser?.phoneNumber != null &&
                      customerUser!.phoneNumber.isNotEmpty)
                  ? customerUser.phoneNumber
                  : defaultPhone;
              final customerName = (customerUser?.fullName != null &&
                      customerUser!.fullName.isNotEmpty)
                  ? customerUser.fullName
                  : (job.customerUid.isNotEmpty
                      ? 'Customer #${job.customerUid.substring(0, job.customerUid.length > 8 ? 8 : job.customerUid.length)}'
                      : 'GezaYo Customer');

              return Column(
                children: [
                  // Floating Top Status Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    color: const Color(0xFF1E293B),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.statusSuccess, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          job.status == DeliveryStatus.assigned
                              ? 'Navigating to pickup...'
                              : 'Status: ${job.status.name.toUpperCase()}',
                          style: AppTypography.titleMedium(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route Map Box
                          SizedBox(
                            height: 140,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: const SimulatedMapWidget(showRoute: true),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer Details Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primaryMint,
                                      child: Icon(Icons.person,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName,
                                            style: AppTypography.titleLarge(
                                                color: theme
                                                    .colorScheme.onSurface),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  size: 14,
                                                  color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text('4.9 Rating',
                                                  style: AppTypography.bodySmall(
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant)),
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
                                              Text(
                                                customerPhone,
                                                style: AppTypography.bodySmall(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            AppColors.statusSuccessBg,
                                        padding: const EdgeInsets.all(10),
                                      ),
                                      icon: const Icon(Icons.phone,
                                          color: AppColors.primary),
                                      onPressed: () =>
                                          PhoneHelper.makePhoneCall(
                                              context, customerPhone),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        color: AppColors.accentOrange,
                                        size: 12),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('PICKUP',
                                              style: AppTypography.labelMedium(
                                                  color:
                                                      AppColors.accentOrange)),
                                          Text(job.pickupAddress,
                                              style: AppTypography.titleMedium(
                                                  color: theme
                                                      .colorScheme.onSurface)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      height: 16,
                                      child: VerticalDivider(
                                          thickness: 1.5,
                                          color: AppColors.cardBorder),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        color: AppColors.statusSuccess,
                                        size: 12),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('DROP-OFF',
                                              style: AppTypography.labelMedium(
                                                  color:
                                                      AppColors.statusSuccess)),
                                          Text(job.dropoffAddress,
                                              style: AppTypography.titleMedium(
                                                  color: theme
                                                      .colorScheme.onSurface)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // PACKAGE DETAILS Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PACKAGE DETAILS',
                                    style: AppTypography.labelMedium(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.surfaceContainerHighest,

                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Type: ${job.packageType.toUpperCase()}',
                                            style: AppTypography.titleLarge(
                                                color: theme
                                                    .colorScheme.onSurface)),
                                        Text('Weight: ${job.weightClass}',
                                            style: AppTypography.bodySmall(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant)),
                                      ],
                                    ),
                                  ],
                                ),
                                if (job.instructions.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline,
                                            color: AppColors.accentOrange,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '"${job.instructions}"',
                                            style: AppTypography.bodySmall(
                                                color: theme
                                                    .colorScheme.onSurface),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // PAYMENT BREAKDOWN Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PAYMENT BREAKDOWN',
                                    style: AppTypography.labelMedium(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 12),
                                _FareRow(
                                    label: 'Offered Fare',
                                    value: 'RWF $fareFormatted'),
                                if (job.tipAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  _FareRow(
                                      label: 'Customer Tip',
                                      value:
                                          '+RWF ${job.tipAmount.toStringAsFixed(0)}',
                                      isBonus: true),
                                ],
                                const Divider(height: 20),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Earnings',
                                            style: AppTypography.headlineMedium(
                                                color: theme
                                                    .colorScheme.onSurface)),
                                        Text('UPON DELIVERY',
                                            style: AppTypography.labelMedium(
                                                color:
                                                    AppColors.statusSuccess)),
                                      ],
                                    ),
                                    Text('RWF $fareFormatted',
                                        style: AppTypography.headlineLarge(
                                            color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border(
                          top: BorderSide(
                              color:
                                  theme.dividerColor.withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'Cancel / Reject',
                            icon: Icons.close,
                            onPressed: () async {
                              await notifier.cancelActiveJob();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: job.status == DeliveryStatus.pickedUp
                                ? 'Resume Navigation to Dropoff'
                                : (job.status == DeliveryStatus.delivered
                                    ? 'Awaiting Confirmation'
                                    : 'Navigate to Pickup'),
                            icon: job.status == DeliveryStatus.pickedUp
                                ? Icons.navigation
                                : Icons.send,
                            onPressed: () {
                              context.push('/rider-navigation');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBonus;

  const _FareRow(
      {required this.label, required this.value, this.isBonus = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium(
                color: theme.colorScheme.onSurfaceVariant)),
        Text(
          value,
          style: AppTypography.titleMedium(
            color:
                isBonus ? AppColors.statusSuccess : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
