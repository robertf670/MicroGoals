import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final premiumStatusProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PremiumNotifier(prefs);
});

class PremiumNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  PremiumNotifier(this._prefs) : super(_prefs.getBool(AppConstants.premiumStatusKey) ?? false);

  Future<void> setPremium(bool value) async {
    await _prefs.setBool(AppConstants.premiumStatusKey, value);
    state = value;
  }
}

