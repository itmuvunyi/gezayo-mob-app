import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../domain/transaction_model.dart';
import '../../presentation/rider_notifier.dart';


class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() =>
      _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  bool _isDailyView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      final uid = user?.uid ?? 'usr-rider-201';
      ref.read(riderNotifierProvider.notifier).syncRiderTransactions(uid);
    });
  }

  void _showWithdrawalModal(double currentBalance) {

    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Withdraw to Mobile Money',
                  style: AppTypography.headlineMedium()),
              const SizedBox(height: 8),
              Text(
                'Available: ${currentBalance.toStringAsFixed(0)} RWF',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (RWF)',
                  hintText: 'Enter amount to withdraw',
                  prefixText: 'RWF ',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    final notifier = ref.read(riderNotifierProvider.notifier);
                    final success = await notifier.withdrawToMoMo(amount);
                    if (ctx.mounted) Navigator.of(ctx).pop();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Withdrawal request of ${amount.toStringAsFixed(0)} RWF sent to MTN MoMo!'
                                : 'Insufficient balance!',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm Withdrawal',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'GezaYo',
        userName: 'Rider Dashboard',
        onNotificationTap: () {},
        onAvatarTap: () => context.push('/profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOTAL BALANCE Banner Card (Dark Green)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33046A38),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: AppTypography.labelMedium(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'RWF ${riderState.totalBalanceRwf.toStringAsFixed(0)}',
                        style: AppTypography.displayLarge(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.trending_up,
                          color: AppColors.primaryMint),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available for withdrawal',
                    style: AppTypography.bodySmall(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          _showWithdrawalModal(riderState.totalBalanceRwf),
                      icon: const Icon(Icons.account_balance_wallet,
                          color: AppColors.primary, size: 20),
                      label: Text(
                        'Withdraw to Mobile Money',
                        style:
                            AppTypography.labelLarge(color: AppColors.primary),
                      ),
                    ),
                  ),


                ],
              ),
            ),

            const SizedBox(height: 20),

            // Earnings Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Earnings Summary',
                          style: AppTypography.headlineMedium(
                              color: theme.colorScheme.onSurface)),

                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.parcelBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isDailyView = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isDailyView
                                      ? AppColors.statusSuccess
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Daily',
                                  style: AppTypography.labelMedium(
                                    color: _isDailyView
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isDailyView = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !_isDailyView
                                      ? AppColors.statusSuccess
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Weekly',
                                  style: AppTypography.labelMedium(
                                    color: !_isDailyView
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Bar Chart Visualization based on real transactions
                  Builder(
                    builder: (context) {
                      final dayEarnings = List<double>.filled(7, 0.0);
                      final now = DateTime.now();
                      final todayWeekdayIndex = (now.weekday - 1) % 7;

                      for (final tx in riderState.transactions) {
                        if (tx.isPositive) {
                          dayEarnings[todayWeekdayIndex] += tx.amountRwf;
                        }
                      }

                      double maxVal =
                          dayEarnings.reduce((a, b) => a > b ? a : b);
                      if (maxVal <= 0) maxVal = 1.0;

                      return SizedBox(
                        height: 150,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 25,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ];
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < days.length) {
                                      final day = days[value.toInt()];
                                      final isToday =
                                          value.toInt() == todayWeekdayIndex;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            color: isToday
                                                ? AppColors.primary
                                                : AppColors.textMuted,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (i) {
                              final height = dayEarnings[i] > 0
                                  ? ((dayEarnings[i] / maxVal) * 20 + 5)
                                  : 0.0;
                              return _makeBarGroup(i, height,
                                  isSelected: i == todayWeekdayIndex);
                            }),
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Earnings",
                              style: AppTypography.bodySmall(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          Text(
                              'RWF ${riderState.earnedTodayRwf.toStringAsFixed(0)}',
                              style: AppTypography.headlineMedium(
                                  color: AppColors.primary)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Trips Completed',
                              style: AppTypography.bodySmall(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          Text('${riderState.jobsDoneToday}',
                              style: AppTypography.headlineMedium(
                                  color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Transactions List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions',
                    style: AppTypography.headlineMedium(
                        color: theme.colorScheme.onSurface)),
                TextButton(
                  onPressed: () {},
                  child: Text('View All',
                      style:
                          AppTypography.titleMedium(color: AppColors.primary)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Transactions List
            if (riderState.transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No transactions yet.',
                    style: AppTypography.bodyMedium(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...riderState.transactions.map((tx) => _TransactionTile(tx: tx)),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/rider');
          if (index == 2) context.push('/profile');
        },
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, {bool isSelected = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx.isPositive
                  ? AppColors.statusSuccessBg
                  : AppColors.groceryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.type == TransactionType.withdrawal
                  ? Icons.account_balance
                  : (tx.type == TransactionType.bonus
                      ? Icons.card_giftcard
                      : Icons.two_wheeler),
              color: tx.isPositive
                  ? AppColors.primary
                  : AppColors.accentOrangeDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(tx.dateText,
                    style: AppTypography.bodySmall(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.isPositive ? "+" : "-"}RWF ${tx.amountRwf.toStringAsFixed(0)}',
                style: AppTypography.titleLarge(
                  color:
                      tx.isPositive ? AppColors.primary : AppColors.statusError,
                ),
              ),
              const SizedBox(height: 2),
              StatusBadge(
                text: tx.status.name.toUpperCase(),
                backgroundColor: tx.status == TransactionStatus.completed
                    ? AppColors.statusSuccessBg
                    : AppColors.groceryBg,
                textColor: tx.status == TransactionStatus.completed
                    ? AppColors.statusSuccess
                    : AppColors.accentOrangeDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
