import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class StorageService {
  static const _itemsKey = 'items';
  static const _onboardingKey = 'onboarding_done';

  Future<List<Item>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_itemsKey);
    if (json == null) return [];
    return Item.listFromJson(json);
  }

  Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_itemsKey, Item.listToJson(items));
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
