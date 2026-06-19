import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class StorageService {
  static const _itemsKey = 'items';
  static const _onboardingKey = 'onboarding_done';
  static const _notificationEnabledKey = 'notification_enabled';
  static const _notificationHourKey = 'notification_hour';
  static const _notificationMinuteKey = 'notification_minute';
  static const _tabOrderKey = 'tab_order';

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

  Future<TimeOfDay?> loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_notificationEnabledKey) ?? false)) return null;
    final hour = prefs.getInt(_notificationHourKey);
    final minute = prefs.getInt(_notificationMinuteKey);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static const _defaultTabOrder = [
    'routine',
    'task',
    'hobby',
    'mindset',
  ];

  Future<List<ItemCategory>> loadTabOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_tabOrderKey);
    final names = saved ?? _defaultTabOrder;
    return names.map(ItemCategory.fromString).toList();
  }

  Future<void> saveTabOrder(List<ItemCategory> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tabOrderKey, order.map((c) => c.name).toList());
  }

  Future<void> saveNotificationTime(TimeOfDay? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.setBool(_notificationEnabledKey, false);
    } else {
      await prefs.setBool(_notificationEnabledKey, true);
      await prefs.setInt(_notificationHourKey, time.hour);
      await prefs.setInt(_notificationMinuteKey, time.minute);
    }
  }
}
