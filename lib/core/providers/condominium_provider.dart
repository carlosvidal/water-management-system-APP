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
      print('[CondominiumProvider] Loading condominiums...');

      final condominiumsData = await _apiService.getCondominiums();
      print('[CondominiumProvider] Received ${condominiumsData.length} condominiums from API');

      if (condominiumsData.isNotEmpty) {
        print('[CondominiumProvider] First condominium sample: ${condominiumsData.first}');
      }

      // Check if the first condominium has blocks data or just _count
      final needsDetailedFetch = condominiumsData.isNotEmpty &&
          (condominiumsData.first is Map) &&
          (condominiumsData.first as Map)['blocks'] == null &&
          (condominiumsData.first as Map)['_count'] != null;

      print('[CondominiumProvider] Needs detailed fetch: $needsDetailedFetch');

      List<Condominium> condominiums;

      if (needsDetailedFetch) {
        print('[CondominiumProvider] Fetching detailed data for each condominium...');
        // Fetch complete data for each condominium
        final detailedData = await Future.wait(
          condominiumsData.map((data) => _apiService.getCondominium(data['id'] as String))
        );
        print('[CondominiumProvider] Converting detailed data to models...');
        condominiums = detailedData.map((data) => Condominium.fromJson(data)).toList();
      } else {
        print('[CondominiumProvider] Converting data to models...');
        condominiums = condominiumsData
            .map((data) {
              print('[CondominiumProvider] Parsing condominium: ${data['id']}');
              try {
                return Condominium.fromJson(data as Map<String, dynamic>);
              } catch (e) {
                print('[CondominiumProvider] ERROR parsing condominium ${data['id']}: $e');
                print('[CondominiumProvider] Problematic data: $data');
                rethrow;
              }
            })
            .toList();
      }

      print('[CondominiumProvider] Successfully parsed ${condominiums.length} condominiums');
      state = AsyncValue.data(condominiums);
    } catch (e, stackTrace) {
      print('[CondominiumProvider] ERROR loading condominiums: $e');
      print('[CondominiumProvider] Stack trace: $stackTrace');

      // Check if it's an authentication error
      if (e is DioException) {
        if (e.response?.statusCode == 401 ||
            (e.response?.statusCode == 500 &&
             e.response?.data?['details']?['stack']?.contains('Invalid access token') == true)) {
          print('[CondominiumProvider] Authentication error detected, logging out user');
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
    error: (_, _) => [],
  );
});

final isLoadingCondominiumsProvider = Provider<bool>((ref) {
  return ref.watch(condominiumProvider).isLoading;
});