import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class StorageService {
  static const _key = 'items';

  Future<List<Item>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    return Item.listFromJson(json);
  }

  Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Item.listToJson(items));
  }
}
