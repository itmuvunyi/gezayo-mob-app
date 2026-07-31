import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_bottom_nav.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'GezaYo Support',
          style: AppTypography.headlineMedium(
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none,
                color: theme.colorScheme.onSurface),
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // How can we help banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: AppTypography.headlineLarge(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse our FAQs or contact us directly for immediate assistance.',
                    style: AppTypography.bodyMedium(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // URGENT HELP Call Emergency Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusError,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.warning, color: Colors.white),
                label: const Text(
                  'URGENT HELP - Call Emergency',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2-Column Action Cards (WhatsApp & Email)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text('WhatsApp',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('Live Support',
                            style:
                                AppTypography.bodySmall(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7), // Blue
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.email, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text('Email Us',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('Reply in 24h',
                            style:
                                AppTypography.bodySmall(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Report a Problem Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: theme.colorScheme.outline, width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.accentOrange, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Report a Problem',
                    style: AppTypography.titleLarge(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Missing items, payment issues, or delivery concerns',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Common Questions / FAQs (ExpansionTile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Common Questions',
                  style: AppTypography.headlineMedium(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'View All',
                  style: AppTypography.titleMedium(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  ExpansionTile(
                    title: Text(
                      'How do I track my GezaYo delivery?',
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'You can track your rider in real-time by tapping on "Orders" in the bottom menu and selecting your active order.',
                          style: AppTypography.bodyMedium(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  ExpansionTile(
                    title: Text(
                      'What are the delivery hours in Kigali?',
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'GezaYo operates 24/7 across Kigali City and surrounding suburbs.',
                          style: AppTypography.bodyMedium(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  ExpansionTile(
                    title: Text(
                      "Can I cancel my order after it's placed?",
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Yes, you can cancel your request before a rider accepts it without any penalty fee.',
                          style: AppTypography.bodyMedium(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support Team Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.headset_mic,
                      size: 48, color: AppColors.primaryMint),
                  const SizedBox(height: 12),
                  Text(
                    'Our team is available 24/7 to support your movement.',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) context.go('/customer');
          if (index == 1) context.push('/live-tracking');
        },
      ),
    );
  }
}
