import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../core/l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// A settings tile that lets the user switch between English and German.
///
/// Drop this into your settings / menu page:
/// ```dart
/// const LanguageSettingsTile(),
/// ```
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<LocaleProvider>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.language, color: Color(0xFFF43F5E), size: 22),
      ),
      title: Text(
        l10n.settingsLanguage,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        provider.isGerman ? 'Deutsch' : 'English',
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: () => _showLanguagePicker(context, provider),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider provider) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _LocaleOption(
                  flag: 'ðŸ‡¬ðŸ‡§',
                  label: 'English',
                  locale: const Locale('en'),
                  selected: provider.isEnglish,
                  onTap: () {
                    provider.setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _LocaleOption(
                  flag: 'ðŸ‡©ðŸ‡ª',
                  label: 'Deutsch',
                  locale: const Locale('de'),
                  selected: provider.isGerman,
                  onTap: () {
                    provider.setLocale(const Locale('de'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocaleOption extends StatelessWidget {
  const _LocaleOption({
    required this.flag,
    required this.label,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFF43F5E) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFFF43F5E)
                    : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFFF43F5E), size: 22),
          ],
        ),
      ),
    );
  }
}