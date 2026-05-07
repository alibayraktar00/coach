import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final bool use24HourFormat;
  /// 1 = Monday, 7 = Sunday (ISO-8601)
  final int weekStartDay;

  const AppSettings({
    required this.locale,
    required this.themeMode,
    required this.use24HourFormat,
    required this.weekStartDay,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? use24HourFormat,
    int? weekStartDay,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      weekStartDay: weekStartDay ?? this.weekStartDay,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _kLocale = 'settings.locale';
  static const _kThemeMode = 'settings.themeMode';
  static const _kUse24h = 'settings.use24h';
  static const _kWeekStart = 'settings.weekStart';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_kLocale) ?? 'tr';
    final themeIndex = prefs.getInt(_kThemeMode) ?? ThemeMode.dark.index;
    final use24h = prefs.getBool(_kUse24h) ?? true;
    final weekStart = prefs.getInt(_kWeekStart) ?? DateTime.monday;

    return AppSettings(
      locale: Locale(localeCode),
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      use24HourFormat: use24h,
      weekStartDay: (weekStart >= 1 && weekStart <= 7) ? weekStart : DateTime.monday,
    );
  }

  Future<void> setLocale(Locale locale) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(locale: locale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setUse24HourFormat(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(use24HourFormat: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUse24h, value);
  }

  Future<void> setWeekStartDay(int day) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final normalized = (day >= 1 && day <= 7) ? day : DateTime.monday;
    state = AsyncData(current.copyWith(weekStartDay: normalized));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeekStart, normalized);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

