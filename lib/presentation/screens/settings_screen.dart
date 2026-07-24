import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../../core/utils/app_settings.dart';
import '../../core/utils/user_profile.dart';
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
                        const _ProfileCard(),
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
                        const SizedBox(height: 32),
                        _SectionHeader(title: l10n.timeFormat, icon: LucideIcons.clock),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              _ChoiceRow(
                                label: l10n.hour24,
                                selected: settings.use24HourFormat,
                                onTap: () => ref
                                    .read(appSettingsProvider.notifier)
                                    .setUse24HourFormat(true),
                              ),
                              _ChoiceRow(
                                label: l10n.hour12,
                                selected: !settings.use24HourFormat,
                                onTap: () => ref
                                    .read(appSettingsProvider.notifier)
                                    .setUse24HourFormat(false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _SectionHeader(title: l10n.weekStart, icon: LucideIcons.calendarRange),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              for (final entry in {
                                DateTime.monday: l10n.monday,
                                DateTime.saturday: l10n.saturday,
                                DateTime.sunday: l10n.sunday,
                              }.entries)
                                _ChoiceRow(
                                  label: entry.value,
                                  selected: settings.weekStartDay == entry.key,
                                  onTap: () => ref
                                      .read(appSettingsProvider.notifier)
                                      .setWeekStartDay(entry.key),
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

/// Editable, persisted profile. Tapping a row opens a small editor.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  Future<void> _editText(
    BuildContext context, {
    required String label,
    required String initial,
    required ValueChanged<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initial);

    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AntigravityTheme.primary),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved != null) onSaved(saved.trim());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const GlassContainer(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Text('$e', style: const TextStyle(color: Colors.white70)),
      ),
      data: (profile) {
        final notifier = ref.read(userProfileProvider.notifier);
        return GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _ProfileField(
                label: l10n.name,
                value: profile.name.isEmpty ? l10n.notSet : profile.name,
                icon: LucideIcons.circleUser,
                onTap: () => _editText(
                  context,
                  label: l10n.name,
                  initial: profile.name,
                  onSaved: notifier.setName,
                ),
              ),
              const Divider(height: 32, color: Colors.white10),
              _ProfileField(
                label: l10n.email,
                value: profile.email.isEmpty ? l10n.notSet : profile.email,
                icon: LucideIcons.mail,
                onTap: () => _editText(
                  context,
                  label: l10n.email,
                  initial: profile.email,
                  keyboardType: TextInputType.emailAddress,
                  onSaved: notifier.setEmail,
                ),
              ),
              const Divider(height: 32, color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: _ProfileField(
                      label: l10n.weight,
                      value: profile.weight == null
                          ? l10n.notSet
                          : '${profile.weight!.toStringAsFixed(0)} kg',
                      icon: LucideIcons.gauge,
                      onTap: () => _editText(
                        context,
                        label: l10n.weight,
                        initial: profile.weight?.toStringAsFixed(0) ?? '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSaved: (value) =>
                            notifier.setWeight(double.tryParse(value.replaceAll(',', '.'))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _ProfileField(
                      label: l10n.height,
                      value: profile.height == null
                          ? l10n.notSet
                          : '${profile.height!.toStringAsFixed(0)} cm',
                      icon: LucideIcons.ruler,
                      onTap: () => _editText(
                        context,
                        label: l10n.height,
                        initial: profile.height?.toStringAsFixed(0) ?? '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSaved: (value) =>
                            notifier.setHeight(double.tryParse(value.replaceAll(',', '.'))),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.white10),
              _ProfileField(
                label: l10n.goal,
                value: profile.goal.isEmpty ? l10n.notSet : profile.goal,
                icon: LucideIcons.target,
                onTap: () => _editText(
                  context,
                  label: l10n.goal,
                  initial: profile.goal,
                  onSaved: notifier.setGoal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _LanguageOption(label: label, selected: selected, onTap: onTap);
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(LucideIcons.pencil, size: 14, color: Colors.white24),
        ],
      ),
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
