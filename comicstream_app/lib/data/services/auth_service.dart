import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../../core/constants/app_constants.dart';

/// Manages authentication state and JWT token storage
class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Save JWT token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  /// Delete JWT token (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  /// Save user data
  Future<void> saveUser(User user) async {
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  /// Get stored user data
  Future<User?> getUser() async {
    final data = await _storage.read(key: AppConstants.userKey);
    if (data != null) {
      return User.fromJson(jsonDecode(data));
    }
    return null;
  }

  /// Delete user data
  Future<void> deleteUser() async {
    await _storage.delete(key: AppConstants.userKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all auth data (full logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
