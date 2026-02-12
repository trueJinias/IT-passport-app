import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyNewCardsPerDay = 'new_cards_per_day';
  
  // Default values
  static const int defaultNewCardsPerDay = 20;

  Future<int> getNewCardsPerDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNewCardsPerDay) ?? defaultNewCardsPerDay;
  }

  Future<void> setNewCardsPerDay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNewCardsPerDay, value);
  }
}
