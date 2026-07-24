import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class UserProfile {
  final String name;
  final String email;
  final String goal;

  /// Kilograms; null when the user has not filled it in.
  final double? weight;

  /// Centimetres; null when the user has not filled it in.
  final double? height;

  const UserProfile({
    this.name = '',
    this.email = '',
    this.goal = '',
    this.weight,
    this.height,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? goal,
    double? weight,
    double? height,
    bool clearWeight = false,
    bool clearHeight = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      goal: goal ?? this.goal,
      weight: clearWeight ? null : (weight ?? this.weight),
      height: clearHeight ? null : (height ?? this.height),
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  static const _kName = 'profile.name';
  static const _kEmail = 'profile.email';
  static const _kGoal = 'profile.goal';
  static const _kWeight = 'profile.weight';
  static const _kHeight = 'profile.height';

  @override
  Future<UserProfile> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString(_kName) ?? '',
      email: prefs.getString(_kEmail) ?? '',
      goal: prefs.getString(_kGoal) ?? '',
      weight: prefs.getDouble(_kWeight),
      height: prefs.getDouble(_kHeight),
    );
  }

  Future<void> _persistString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Stores a measurement, removing it when [value] is null.
  Future<void> _persistDouble(String key, double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setDouble(key, value);
    }
  }

  Future<void> setName(String value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(name: value));
    await _persistString(_kName, value);
  }

  Future<void> setEmail(String value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(email: value));
    await _persistString(_kEmail, value);
  }

  Future<void> setGoal(String value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(goal: value));
    await _persistString(_kGoal, value);
  }

  Future<void> setWeight(double? value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(weight: value, clearWeight: value == null));
    await _persistDouble(_kWeight, value);
  }

  Future<void> setHeight(double? value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(height: value, clearHeight: value == null));
    await _persistDouble(_kHeight, value);
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
