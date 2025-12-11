import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';

class CondominiumDetailNotifier extends StateNotifier<AsyncValue<Condominium?>> {
  final ApiService _apiService;
  final String condominiumId;

  CondominiumDetailNotifier(this._apiService, this.condominiumId) 
      : super(const AsyncValue.loading()) {
    loadCondominium();
  }

  Future<void> loadCondominium() async {
    try {
      state = const AsyncValue.loading();
      final condominiumData = await _apiService.getCondominium(condominiumId);
      
      // Debug: print the full response to identify the problematic field
      // Loading condominium details
      
      final condominium = Condominium.fromJson(condominiumData);
      state = AsyncValue.data(condominium);
    } catch (e, stackTrace) {
      // Error loading condominium
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createBlock(String name, int maxUnits) async {
    try {
      await _apiService.createBlock(condominiumId, {
        'name': name,
        'maxUnits': maxUnits,
      });
      // Reload condominium data after creating block
      await loadCondominium();
    } catch (e) {
      // Error creating block
      rethrow;
    }
  }

  Future<void> createUnit(String blockId, String name) async {
    try {
      await _apiService.createUnit(condominiumId, {
        'name': name,
        'blockId': blockId,
      });
      // Reload condominium data after creating unit
      await loadCondominium();
    } catch (e) {
      // Error creating unit
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadCondominium();
  }
}

// Provider factory
final condominiumDetailProvider = StateNotifierProvider.family<CondominiumDetailNotifier, AsyncValue<Condominium?>, String>((ref, condominiumId) {
  final apiService = ref.read(apiServiceProvider);
  return CondominiumDetailNotifier(apiService, condominiumId);
});

// Convenience providers
final condominiumDetailDataProvider = Provider.family<Condominium?, String>((ref, condominiumId) {
  return ref.watch(condominiumDetailProvider(condominiumId)).when(
    data: (condominium) => condominium,
    loading: () => null,
    error: (_, _) => null,
  );
});

final isLoadingCondominiumDetailProvider = Provider.family<bool, String>((ref, condominiumId) {
  return ref.watch(condominiumDetailProvider(condominiumId)).isLoading;
});