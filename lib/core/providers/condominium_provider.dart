import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';
import 'package:water_readings_app/core/providers/auth_provider.dart';

class CondominiumNotifier extends StateNotifier<AsyncValue<List<Condominium>>> {
  final ApiService _apiService;
  final Ref _ref;

  CondominiumNotifier(this._apiService, this._ref) : super(const AsyncValue.loading()) {
    loadCondominiums();
  }

  Future<void> loadCondominiums() async {
    try {
      state = const AsyncValue.loading();
      final condominiumsData = await _apiService.getCondominiums();
      final condominiums = condominiumsData
          .map((data) => Condominium.fromJson(data))
          .toList();
      state = AsyncValue.data(condominiums);
    } catch (e, stackTrace) {
      // Error loading condominiums
      
      // Check if it's an authentication error
      if (e is DioException) {
        if (e.response?.statusCode == 401 || 
            (e.response?.statusCode == 500 && 
             e.response?.data?['details']?['stack']?.contains('Invalid access token') == true)) {
          // Authentication error detected, logging out user
          // Force logout on authentication errors
          _ref.read(authProvider.notifier).logout();
          return;
        }
      }
      
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createCondominium(Map<String, dynamic> data) async {
    try {
      await _apiService.createCondominium(data);
      // Reload the list after creation
      await loadCondominiums();
    } catch (e) {
      // Error creating condominium
      rethrow;
    }
  }

  Future<void> createCondominiumWithStructure(Map<String, dynamic> data) async {
    try {
      await _apiService.createCondominiumWithStructure(data);
      // Reload the list after creation
      await loadCondominiums();
    } catch (e) {
      // Error creating condominium with structure
      rethrow;
    }
  }

  Future<void> refreshCondominiums() async {
    await loadCondominiums();
  }
}

// Provider
final condominiumProvider = StateNotifierProvider<CondominiumNotifier, AsyncValue<List<Condominium>>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return CondominiumNotifier(apiService, ref);
});

// Convenience providers
final condominiumListProvider = Provider<List<Condominium>>((ref) {
  return ref.watch(condominiumProvider).when(
    data: (condominiums) => condominiums,
    loading: () => [],
    error: (_, __) => [],
  );
});

final isLoadingCondominiumsProvider = Provider<bool>((ref) {
  return ref.watch(condominiumProvider).isLoading;
});