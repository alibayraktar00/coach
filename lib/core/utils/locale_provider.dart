import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_settings.dart';

final localeProvider = StateProvider<Locale>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return settings?.locale ?? const Locale('tr');
});
