import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // User data operations
  Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _userKey, value: userJson);
    } catch (e) {
      throw StorageException('Failed to save user data: ${e.toString()}');
    }
  }

  Future<User?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      throw StorageException('Failed to retrieve user data: ${e.toString()}');
    }
  }

  Future<void> deleteUser() async {
    try {
      await _storage.delete(key: _userKey);
    } catch (e) {
      throw StorageException('Failed to delete user data: ${e.toString()}');
    }
  }

  // Login state operations
  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      await _storage.write(key: _isLoggedInKey, value: isLoggedIn.toString());
    } catch (e) {
      throw StorageException('Failed to save login state: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final isLoggedInString = await _storage.read(key: _isLoggedInKey);
      return isLoggedInString == 'true';
    } catch (e) {
      throw StorageException('Failed to retrieve login state: ${e.toString()}');
    }
  }

  // Clear all data (logout)
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to clear all data: ${e.toString()}');
    }
  }

  // Check if user data exists
  Future<bool> hasUserData() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      return userJson != null;
    } catch (e) {
      return false;
    }
  }

  // Check if user has a valid authentication session
  Future<bool> hasValidSession() async {
    try {
      final isLoggedIn = await this.isLoggedIn();
      final hasUserData = await this.hasUserData();
      
      // Since the API doesn't return tokens, we only check login state and user data
      return isLoggedIn && hasUserData;
    } catch (e) {
      return false;
    }
  }
}

class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
} 