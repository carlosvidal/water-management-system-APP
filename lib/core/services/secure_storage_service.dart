import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _selectedCondominiumKey = 'selected_condominium';

  // Token management
  Future<void> storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> storeRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // User data
  Future<void> storeUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  // Selected condominium
  Future<void> storeSelectedCondominium(String condominiumId) async {
    await _storage.write(key: _selectedCondominiumKey, value: condominiumId);
  }

  Future<String?> getSelectedCondominium() async {
    return await _storage.read(key: _selectedCondominiumKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear auth data only
  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Store login credentials (email only - never store passwords)
  Future<void> storeLastEmail(String email) async {
    await _storage.write(key: 'last_email', value: email);
  }

  Future<String?> getLastEmail() async {
    return await _storage.read(key: 'last_email');
  }
}

// Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});