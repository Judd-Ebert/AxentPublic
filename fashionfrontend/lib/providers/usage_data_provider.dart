import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageDataProvider extends ChangeNotifier {
  int _totalSwipes = 0;
  int _likesCount = 0;
  int _dislikesCount = 0;
  int _wardrobesCreated = 0;
  int _productsInWardrobes = 0;
  DateTime? _firstLoginDate;
  int _daysActive = 0;
  
  int get totalSwipes => _totalSwipes;
  int get likesCount => _likesCount;
  int get dislikesCount => _dislikesCount;
  int get wardrobesCreated => _wardrobesCreated;
  int get productsInWardrobes => _productsInWardrobes;
  DateTime? get firstLoginDate => _firstLoginDate;
  int get daysActive => _daysActive;
  
  double get likeRatio => _totalSwipes > 0 ? (_likesCount / _totalSwipes) * 100 : 0;
  
  Future<void> loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    _totalSwipes = prefs.getInt('usage_total_swipes') ?? 0;
    _likesCount = prefs.getInt('usage_likes_count') ?? 0;
    _dislikesCount = prefs.getInt('usage_dislikes_count') ?? 0;
    _wardrobesCreated = prefs.getInt('usage_wardrobes_created') ?? 0;
    _productsInWardrobes = prefs.getInt('usage_products_in_wardrobes') ?? 0;
    _daysActive = prefs.getInt('usage_days_active') ?? 0;
    
    final firstLoginTimestamp = prefs.getInt('usage_first_login');
    if (firstLoginTimestamp != null) {
      _firstLoginDate = DateTime.fromMillisecondsSinceEpoch(firstLoginTimestamp);
    }
    
    notifyListeners();
  }
  
  Future<void> incrementSwipes(bool isLike) async {
    final prefs = await SharedPreferences.getInstance();
    _totalSwipes++;
    if (isLike) {
      _likesCount++;
    } else {
      _dislikesCount++;
    }
    
    await prefs.setInt('usage_total_swipes', _totalSwipes);
    await prefs.setInt('usage_likes_count', _likesCount);
    await prefs.setInt('usage_dislikes_count', _dislikesCount);
    notifyListeners();
  }
  
  Future<void> incrementWardrobes() async {
    final prefs = await SharedPreferences.getInstance();
    _wardrobesCreated++;
    await prefs.setInt('usage_wardrobes_created', _wardrobesCreated);
    notifyListeners();
  }
  
  Future<void> updateProductsInWardrobes(int count) async {
    final prefs = await SharedPreferences.getInstance();
    _productsInWardrobes = count;
    await prefs.setInt('usage_products_in_wardrobes', _productsInWardrobes);
    notifyListeners();
  }
  
  Future<void> recordDailyActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastActivityString = prefs.getString('usage_last_activity_date');
    
    // Set first login date if not set
    if (_firstLoginDate == null) {
      _firstLoginDate = today;
      await prefs.setInt('usage_first_login', today.millisecondsSinceEpoch);
    }
    
    // Check if this is a new day of activity
    if (lastActivityString != null) {
      final lastActivity = DateTime.parse(lastActivityString);
      if (!_isSameDay(today, lastActivity)) {
        _daysActive++;
        await prefs.setInt('usage_days_active', _daysActive);
      }
    } else {
      _daysActive = 1;
      await prefs.setInt('usage_days_active', _daysActive);
    }
    
    await prefs.setString('usage_last_activity_date', today.toIso8601String());
    notifyListeners();
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  Future<void> resetUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'usage_total_swipes',
      'usage_likes_count',
      'usage_dislikes_count',
      'usage_wardrobes_created',
      'usage_products_in_wardrobes',
      'usage_first_login',
      'usage_days_active',
      'usage_last_activity_date',
    ];
    
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    _totalSwipes = 0;
    _likesCount = 0;
    _dislikesCount = 0;
    _wardrobesCreated = 0;
    _productsInWardrobes = 0;
    _firstLoginDate = null;
    _daysActive = 0;
    
    notifyListeners();
  }
}
