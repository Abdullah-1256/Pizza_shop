import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteManager {
  static final FavoriteManager _instance = FavoriteManager._internal();
  factory FavoriteManager() => _instance;
  FavoriteManager._internal();

  static const String _favoritesKey = 'favorite_items';
  Set<String> _favorites = {};
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadFavorites();
      _isInitialized = true;
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favorites = Set<String>.from(favoritesList);
      }
    } catch (e) {
      print('Error loading favorites: $e');
      _favorites = {};
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(_favorites.toList());
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  Future<void> toggleFavorite(String productName) async {
    await _ensureInitialized();
    if (_favorites.contains(productName)) {
      _favorites.remove(productName);
    } else {
      _favorites.add(productName);
    }
    await _saveFavorites();
  }

  Future<bool> isFavorite(String productName) async {
    await _ensureInitialized();
    return _favorites.contains(productName);
  }

  Future<List<String>> getFavorites() async {
    await _ensureInitialized();
    return _favorites.toList();
  }

  // Synchronous versions for backward compatibility (will initialize if needed)
  void toggleFavoriteSync(String productName) {
    if (_favorites.contains(productName)) {
      _favorites.remove(productName);
    } else {
      _favorites.add(productName);
    }
    _saveFavorites(); // Don't await here for sync method
  }

  bool isFavoriteSync(String productName) {
    return _favorites.contains(productName);
  }

  List<String> getFavoritesSync() {
    return _favorites.toList();
  }
}
