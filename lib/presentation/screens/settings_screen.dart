import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../../core/utils/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/icon_glass_button.dart';
import '../widgets/glow_circle.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: GlowCircle(color: AntigravityTheme.primary.withAlpha((255 * 0.2).toInt()), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: GlowCircle(color: AntigravityTheme.secondary.withAlpha((255 * 0.15).toInt()), size: 400),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconGlassButton(
                        icon: LucideIcons.chevronLeft,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        l10n.settings,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: settingsAsync.when(
                    data: (settings) => ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _SectionHeader(title: l10n.profile, icon: LucideIcons.user),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              _ProfileField(label: l10n.name, value: 'John Doe', icon: LucideIcons.circleUser),
                              const Divider(height: 32, color: Colors.white10),
                              _ProfileField(label: l10n.email, value: 'john@example.com', icon: LucideIcons.mail),
                              const Divider(height: 32, color: Colors.white10),
                              Row(
                                children: [
                                  Expanded(child: _ProfileField(label: l10n.weight, value: '75 kg', icon: LucideIcons.gauge)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _ProfileField(label: l10n.height, value: '180 cm', icon: LucideIcons.ruler)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _SectionHeader(title: l10n.theme, icon: LucideIcons.palette),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              _ThemeOption(
                                label: l10n.light,
                                icon: LucideIcons.sun,
                                selected: settings.themeMode == ThemeMode.light,
                                onTap: () => ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.light),
                              ),
                              _ThemeOption(
                                label: l10n.dark,
                                icon: LucideIcons.moon,
                                selected: settings.themeMode == ThemeMode.dark,
                                onTap: () => ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.dark),
                              ),
                              _ThemeOption(
                                label: l10n.system,
                                icon: LucideIcons.monitor,
                                selected: settings.themeMode == ThemeMode.system,
                                onTap: () => ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.system),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _SectionHeader(title: l10n.language, icon: LucideIcons.languages),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              _LanguageOption(
                                label: l10n.turkish,
                                selected: settings.locale.languageCode == 'tr',
                                onTap: () => ref.read(appSettingsProvider.notifier).setLocale(const Locale('tr')),
                              ),
                              _LanguageOption(
                                label: l10n.english,
                                selected: settings.locale.languageCode == 'en',
                                onTap: () => ref.read(appSettingsProvider.notifier).setLocale(const Locale('en')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AntigravityTheme.primary),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileField({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((255 * 0.05).toInt()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha((255 * 0.08).toInt()) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AntigravityTheme.primary : Colors.white60),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(LucideIcons.check, size: 20, color: AntigravityTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha((255 * 0.08).toInt()) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(LucideIcons.check, size: 20, color: AntigravityTheme.primary),
          ],
        ),
      ),
    );
  }
}
