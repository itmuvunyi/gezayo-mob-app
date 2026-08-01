import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../rider/domain/transaction_model.dart';
import '../../rider/presentation/rider_notifier.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController(text: '5000');
  final _phoneController = TextEditingController();
  String _selectedMethod = 'momo'; // 'momo', 'airtel', 'card'
  double _selectedPreset = 5000;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final userPhone = ref.read(authNotifierProvider).user?.phoneNumber ?? '';
    if (userPhone.isNotEmpty) {
      _phoneController.text = userPhone;
    } else {
      _phoneController.text = '+250 788 000 000';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount < 500) {
      setState(() => _errorMessage = 'Minimum deposit amount is 500 RWF.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(authNotifierProvider).user;
      final uid = user?.uid ?? 'usr-customer-101';
      final firestoreService = ref.read(firestoreServiceProvider);

      final tx = TransactionModel(
        id: 'tx-dep-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        userId: uid,
        title: _selectedMethod == 'momo'
            ? 'Deposit via MTN MoMo'
            : (_selectedMethod == 'airtel'
                ? 'Deposit via Airtel Money'
                : 'Deposit via Credit/Debit Card'),
        dateText: 'Just now',
        amountRwf: amount,
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
      );

      await firestoreService.addTransaction(tx);

      if (user?.isRider == true) {
        ref.read(riderNotifierProvider.notifier).syncRiderTransactions(uid);
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully deposited RWF ${amount.toStringAsFixed(0)} to your wallet!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Deposit failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'GezaYo Wallet',
        onNotificationTap: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF046A38), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Deposit Funds',
                    style: AppTypography.displayMedium(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instantly top up your GezaYo wallet balance for seamless deliveries.',
                    style: AppTypography.bodySmall(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Select Payment Method',
              style:
                  AppTypography.headlineMedium(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),

            // Payment Methods Row
            Row(
              children: [
                _MethodCard(
                  title: 'MTN MoMo',
                  icon: Icons.phone_android,
                  color: const Color(0xFFFFCC00),
                  textColor: Colors.black87,
                  isSelected: _selectedMethod == 'momo',
                  onTap: () => setState(() => _selectedMethod = 'momo'),
                ),
                const SizedBox(width: 10),
                _MethodCard(
                  title: 'Airtel Money',
                  icon: Icons.cell_tower,
                  color: Colors.redAccent,
                  textColor: Colors.white,
                  isSelected: _selectedMethod == 'airtel',
                  onTap: () => setState(() => _selectedMethod = 'airtel'),
                ),
                const SizedBox(width: 10),
                _MethodCard(
                  title: 'Bank Card',
                  icon: Icons.credit_card,
                  color: AppColors.primary,
                  textColor: Colors.white,
                  isSelected: _selectedMethod == 'card',
                  onTap: () => setState(() => _selectedMethod = 'card'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Deposit Amount (RWF)',
              style:
                  AppTypography.headlineMedium(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),

            // Preset Amount Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1000.0, 2000.0, 5000.0, 10000.0].map((preset) {
                final isSelected = _selectedPreset == preset;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = preset;
                      _amountController.text = preset.toStringAsFixed(0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryMint
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : theme.dividerColor.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${preset.toStringAsFixed(0)} RWF',
                      style: AppTypography.labelLarge(
                        color: isSelected
                            ? AppColors.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            AppTextField(
              label: 'Custom Amount (RWF)',
              hintText: 'Enter deposit amount',
              controller: _amountController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            AppTextField(
              label: _selectedMethod == 'card'
                  ? 'Card Number'
                  : 'Mobile Phone Number',
              hintText: _selectedMethod == 'card'
                  ? '4532 •••• •••• 8910'
                  : 'e.g. +250 788 123 456',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusErrorBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.statusError.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall(color: AppColors.statusError),
                ),
              ),
            ],

            const SizedBox(height: 28),

            PrimaryButton(
              text: 'Complete Deposit',
              icon: Icons.account_balance_wallet,
              isLoading: _isLoading,
              onPressed: _isLoading ? () {} : _handleDeposit,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: isSelected ? color : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.labelMedium(
                  color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
