import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService extends ChangeNotifier {
  FavoriteService._();

  static final FavoriteService instance = FavoriteService._();

  static const String _storageKey = 'favourite_restaurant_ids';

  final Set<String> _favouriteIds = <String>{};

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Set<String> get favouriteIds => Set.unmodifiable(_favouriteIds);

  bool isFavorite(String restaurantId) {
    return _favouriteIds.contains(restaurantId);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_storageKey) ?? [];

    _favouriteIds
      ..clear()
      ..addAll(savedIds);

    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(String restaurantId) async {
    if (!_initialized) {
      await initialize();
    }

    if (_favouriteIds.contains(restaurantId)) {
      _favouriteIds.remove(restaurantId);
    } else {
      _favouriteIds.add(restaurantId);
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _storageKey,
      _favouriteIds.toList(),
    );
  }
}
