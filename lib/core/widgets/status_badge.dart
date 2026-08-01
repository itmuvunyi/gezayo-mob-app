import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.statusSuccessBg,
    this.textColor = AppColors.statusSuccess,
    this.icon,
  });

  factory StatusBadge.live() => const StatusBadge(
        text: 'Live',
        backgroundColor: AppColors.statusSuccessBg,
        textColor: AppColors.statusSuccess,
        icon: Icons.circle,
      );

  factory StatusBadge.urgent() => const StatusBadge(
        text: 'URGENT',
        backgroundColor: AppColors.statusErrorBg,
        textColor: AppColors.statusError,
      );

  factory StatusBadge.onTheWay() => const StatusBadge(
        text: 'On the way',
        backgroundColor: AppColors.statusSuccessBg,
        textColor: AppColors.primary,
      );

  factory StatusBadge.searching() => const StatusBadge(
        text: 'Searching',
        backgroundColor: AppColors.statusErrorBg,
        textColor: AppColors.accentOrange,
      );

  factory StatusBadge.completed() => const StatusBadge(
        text: 'COMPLETED',
        backgroundColor: AppColors.statusSuccessBg,
        textColor: AppColors.statusSuccess,
      );

  factory StatusBadge.reward() => const StatusBadge(
        text: 'REWARD',
        backgroundColor: AppColors.statusSuccessBg,
        textColor: AppColors.statusSuccess,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.labelMedium(color: textColor),
          ),
        ],
      ),
    );
  }
}
