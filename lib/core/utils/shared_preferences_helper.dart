import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class SharedPreferencesHelper {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isAdminKey = 'is_admin';
  static const String _adminTokenKey = 'admin_token';

  static Future<void> saveUserData(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  static Future<UserEntity?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserEntity(
        id: userMap['id'],
        email: userMap['email'],
        name: userMap['name'],
        photoUrl: userMap['photoUrl'],
        phone: userMap['phone'],
        isEmailVerified: userMap['isEmailVerified'] ?? false,
        createdAt: userMap['createdAt'] != null
            ? DateTime.parse(userMap['createdAt'])
            : null,
        updatedAt: userMap['updatedAt'] != null
            ? DateTime.parse(userMap['updatedAt'])
            : null,
        emailConfirmedAt: userMap['emailConfirmedAt'] != null
            ? DateTime.parse(userMap['emailConfirmedAt'])
            : null,
        lastSignInAt: userMap['lastSignInAt'] != null
            ? DateTime.parse(userMap['lastSignInAt'])
            : null,
        userMetadata: userMap['userMetadata'],
        appMetadata: userMap['appMetadata'],
        isAnonymous: userMap['isAnonymous'] ?? false,
        role: userMap['role'] ?? 'authenticated',
        aud: userMap['aud'] ?? 'authenticated',
      );
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = await getUserData();
    if (user != null) {
      return {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'photoUrl': user.photoUrl,
        'phone': user.phone,
        'isEmailVerified': user.isEmailVerified,
        'createdAt': user.createdAt?.toIso8601String(),
        'lastSignInAt': user.lastSignInAt?.toIso8601String(),
      };
    }
    return null;
  }

  static Future<void> updateUserProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final user = await getUserData();
    if (user != null) {
      final updatedUser = user.copyWith(
        name: name ?? user.name,
        email: email ?? user.email,
        phone: phone ?? user.phone,
      );
      await saveUserData(updatedUser);
    }
  }

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Admin-specific methods
  static Future<void> setAdminStatus(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdminKey, isAdmin);
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  static Future<void> saveAdminToken(String adminToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, adminToken);
  }

  static Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminTokenKey);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_adminTokenKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
