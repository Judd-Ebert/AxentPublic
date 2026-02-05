import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  bool _pushNotifications = true;
  bool _newProductAlerts = true;
  bool _priceDropAlerts = true;
  bool _wardrobeReminders = false;
  
  bool get pushNotifications => _pushNotifications;
  bool get newProductAlerts => _newProductAlerts;
  bool get priceDropAlerts => _priceDropAlerts;
  bool get wardrobeReminders => _wardrobeReminders;
  
  Future<void> loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool('push_notifications') ?? true;
    _newProductAlerts = prefs.getBool('new_product_alerts') ?? true;
    _priceDropAlerts = prefs.getBool('price_drop_alerts') ?? true;
    _wardrobeReminders = prefs.getBool('wardrobe_reminders') ?? false;
    notifyListeners();
  }
  
  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
  }
  
  Future<void> setNewProductAlerts(bool value) async {
    _newProductAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('new_product_alerts', value);
  }
  
  Future<void> setPriceDropAlerts(bool value) async {
    _priceDropAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('price_drop_alerts', value);
  }
  
  Future<void> setWardrobeReminders(bool value) async {
    _wardrobeReminders = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wardrobe_reminders', value);
  }
}
