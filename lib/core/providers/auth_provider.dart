import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/auth_state.dart';
import 'package:water_readings_app/core/models/user.dart';
import 'package:water_readings_app/core/services/api_service.dart';
import 'package:water_readings_app/core/services/secure_storage_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._apiService, this._secureStorage) : super(const AuthState.initial()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Starting authentication initialization
      state = const AuthState.loading();
      
      final token = await _secureStorage.getToken();
      final userDataJson = await _secureStorage.getUserData();
      
      // Checking stored authentication data
      
      if (token != null && userDataJson != null) {
        try {
          final userData = jsonDecode(userDataJson);
          final user = User.fromJson(userData);
          
          final refreshToken = await _secureStorage.getRefreshToken();
          
          // Setting authenticated state for user
          state = AuthState.authenticated(
            user: user,
            token: token,
            refreshToken: refreshToken,
          );
        } catch (e) {
          // Error parsing stored user data
          // If stored user data is invalid, clear it and show unauthenticated
          await _secureStorage.clearAuthData();
          state = const AuthState.unauthenticated();
        }
      } else {
        // No stored credentials, show unauthenticated (login screen)
        // No stored credentials, setting unauthenticated
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      // Authentication initialization failed
      // If initialization fails completely, show unauthenticated
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AuthState.loading();
      
      // Demo login disabled - using real backend API
      // if (email == 'demo@aquaflow.com' && password == 'demo123') {
      //   final demoUser = User(
      //     id: 'demo-user-id',
      //     email: email,
      //     name: 'Demo User',
      //     role: 'ADMIN',
      //     isActive: true,
      //   );
      //   
      //   const demoToken = 'demo-token-123';
      //   
      //   // Store credentials securely
      //   await _secureStorage.storeToken(demoToken);
      //   await _secureStorage.storeUserData(jsonEncode(demoUser.toJson()));
      //   await _secureStorage.storeLastEmail(email);
      //   
      //   state = AuthState.authenticated(
      //     user: demoUser,
      //     token: demoToken,
      //     refreshToken: 'demo-refresh-token',
      //   );
      //   return;
      // }
      
      // Try real API login
      final response = await _apiService.login(email, password);
      
      final user = User.fromJson(response['user']);
      final token = response['accessToken'];
      final refreshToken = response['refreshToken'];
      
      // Store credentials securely
      await _secureStorage.storeToken(token);
      await _secureStorage.storeUserData(jsonEncode(user.toJson()));
      
      if (refreshToken != null) {
        await _secureStorage.storeRefreshToken(refreshToken);
      }
      
      // Store last used email for convenience
      await _secureStorage.storeLastEmail(email);
      
      state = AuthState.authenticated(
        user: user,
        token: token,
        refreshToken: refreshToken,
      );
    } catch (e) {
      String errorMessage = 'Login failed';
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Invalid email or password';
      } else if (e.toString().contains('ConnectionException')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      }
      
      state = AuthState.error(errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      // Call logout endpoint if authenticated
      if (state.isAuthenticated) {
        await _apiService.logout();
      }
    } catch (e) {
      // Ignore logout API errors - always clear local storage
    } finally {
      // Clear local storage
      await _secureStorage.clearAuthData();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> refreshToken() async {
    try {
      if (!state.isAuthenticated || state.refreshToken == null) {
        throw Exception('No refresh token available');
      }

      // The API service will handle token refresh automatically
      // This method is for manual refresh if needed
      
      final token = await _secureStorage.getToken();
      if (token != null && state.user != null) {
        state = state.copyWith(token: token);
      }
    } catch (e) {
      // Refresh failed, logout user
      await logout();
    }
  }

  Future<void> updateUser(User updatedUser) async {
    if (state.isAuthenticated) {
      await _secureStorage.storeUserData(jsonEncode(updatedUser.toJson()));
      state = state.copyWith(user: updatedUser);
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AuthState.unauthenticated();
    }
  }

  // Helper methods
  bool get isAuthenticated => state.isAuthenticated;
  bool get isLoading => state.isLoading;
  bool get hasError => state.hasError;
  
  User? get currentUser => state.user;
  String? get currentToken => state.token;
  
  bool get isSuperAdmin => state.user?.role == 'SUPER_ADMIN';
  bool get isAdmin => state.user?.role == 'ADMIN';
  bool get isEditor => state.user?.role == 'EDITOR';
  bool get isAnalyst => state.user?.role == 'ANALYST';
  
  bool hasRole(List<String> roles) {
    return state.user != null && roles.contains(state.user!.role);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final secureStorage = ref.read(secureStorageProvider);
  return AuthNotifier(apiService, secureStorage);
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});