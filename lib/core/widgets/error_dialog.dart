import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onConfirm,
  });

  static Future<void> show(BuildContext context, String message,
      {String title = 'Error'}) {
    return showDialog(
      context: context,
      builder: (ctx) => ErrorDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusError),
          const SizedBox(width: 8),
          Text(title, style: AppTypography.headlineMedium()),
        ],
      ),
      content: Text(message, style: AppTypography.bodyMedium()),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onConfirm != null) onConfirm!();
          },
          child: Text('OK',
              style: AppTypography.labelLarge(color: AppColors.primary)),
        ),
      ],
    );
  }
}
