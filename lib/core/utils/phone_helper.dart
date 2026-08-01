import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneHelper {
  /// Dial phone number via native phone app or show dialog fallback
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided.')),
      );
      return;
    }

    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showCallDialog(context, phoneNumber);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showCallDialog(context, phoneNumber);
      }
    }
  }

  static void _showCallDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('Contact Phone'),
          ],
        ),
        content: Text('Phone Number: $phoneNumber'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
              final uri = Uri.parse('tel:$cleanPhone');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text('Call Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
