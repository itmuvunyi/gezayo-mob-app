import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/auth_notifier.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  final List<_LanguageItem> _languages = const [
    _LanguageItem(name: 'English', nativeName: 'English (US/UK)', code: 'en'),
    _LanguageItem(name: 'Kinyarwanda', nativeName: 'Ikinyarwanda', code: 'rw'),
    _LanguageItem(name: 'Français', nativeName: 'Français', code: 'fr'),
    _LanguageItem(name: 'Kiswahili', nativeName: 'Kiswahili', code: 'sw'),
    _LanguageItem(name: 'Luganda', nativeName: 'Oluganda', code: 'lg'),
    _LanguageItem(name: 'Español', nativeName: 'Español', code: 'es'),
    _LanguageItem(name: 'Português', nativeName: 'Português', code: 'pt'),
    _LanguageItem(name: 'Deutsch', nativeName: 'Deutsch', code: 'de'),
  ];


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final selectedLang = authState.selectedLanguage;
    final notifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'App Language',
          style: AppTypography.headlineMedium(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your preferred language. Changes apply across the entire app.',
              style: AppTypography.bodyMedium(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: List.generate(_languages.length, (index) {
                  final item = _languages[index];
                  final isSelected = selectedLang == item.name;
                  return Column(
                    children: [
                      ListTile(
                        onTap: () {
                          notifier.setLanguage(item.name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language set to ${item.name}!'),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : AppColors.parcelBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.language,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: AppTypography.titleLarge(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          item.nativeName,
                          style: AppTypography.bodySmall(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: theme.colorScheme.primary)
                            : Icon(Icons.radio_button_unchecked,
                                color: theme.colorScheme.outline),
                      ),
                      if (index < _languages.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageItem {
  final String name;
  final String nativeName;
  final String code;

  const _LanguageItem({
    required this.name,
    required this.nativeName,
    required this.code,
  });
}
