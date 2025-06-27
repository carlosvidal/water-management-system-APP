import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';
import 'package:water_readings_app/core/providers/auth_provider.dart';

class ResidentsNotifier extends StateNotifier<AsyncValue<List<Resident>>> {
  final ApiService _apiService;
  final Ref _ref;
  final String _condominiumId;

  ResidentsNotifier(this._apiService, this._ref, this._condominiumId) 
      : super(const AsyncValue.loading()) {
    loadResidents();
  }

  Future<void> loadResidents({String? search}) async {
    try {
      state = const AsyncValue.loading();
      final residentsData = await _apiService.getCondominiumResidents(
        _condominiumId,
        search: search,
      );
      final residents = residentsData
          .map((data) => Resident.fromJson(data))
          .toList();
      state = AsyncValue.data(residents);
    } catch (e, stackTrace) {
      // Error loading residents
      
      // Check if it's an authentication error
      if (e is DioException) {
        if (e.response?.statusCode == 401 || 
            (e.response?.statusCode == 500 && 
             e.response?.data?['details']?['stack']?.contains('Invalid access token') == true)) {
          // Authentication error detected, logging out user
          _ref.read(authProvider.notifier).logout();
          return;
        }
      }
      
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Resident> createResident({
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final data = {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      
      final response = await _apiService.createResident(_condominiumId, data);
      // El backend retorna directamente el residente, no en un wrapper
      final newResident = Resident.fromJson(response);
      
      // Update local state
      await loadResidents();
      
      return newResident;
    } catch (e) {
      // Error creating resident
      rethrow;
    }
  }

  Future<void> updateResident({
    required String residentId,
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final data = {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      
      await _apiService.updateResident(_condominiumId, residentId, data);
      
      // Update local state
      await loadResidents();
    } catch (e) {
      // Error updating resident
      rethrow;
    }
  }

  Future<void> assignResidentToUnit(String unitId, String residentId) async {
    try {
      await _apiService.assignResidentToUnit(_condominiumId, unitId, residentId);
    } catch (e) {
      // Error assigning resident to unit
      rethrow;
    }
  }

  // New methods for multiple residents per unit
  Future<void> addResidentToUnit(String unitId, String residentId, {bool isPrimary = false}) async {
    try {
      await _apiService.addResidentToUnit(_condominiumId, unitId, residentId, isPrimary: isPrimary);
    } catch (e) {
      // Error adding resident to unit
      rethrow;
    }
  }

  Future<void> removeResidentFromUnit(String unitId, String residentId) async {
    try {
      await _apiService.removeResidentFromUnit(_condominiumId, unitId, residentId);
    } catch (e) {
      // Error removing resident from unit
      rethrow;
    }
  }

  Future<List<dynamic>> getUnitResidents(String unitId) async {
    try {
      return await _apiService.getUnitResidents(_condominiumId, unitId);
    } catch (e) {
      // Error getting unit residents
      rethrow;
    }
  }

  Future<void> refreshResidents() async {
    await loadResidents();
  }
}

// Provider factory
final residentsProvider = StateNotifierProvider.family<ResidentsNotifier, AsyncValue<List<Resident>>, String>((ref, condominiumId) {
  final apiService = ref.read(apiServiceProvider);
  return ResidentsNotifier(apiService, ref, condominiumId);
});

// Convenience providers
final residentsListProvider = Provider.family<List<Resident>, String>((ref, condominiumId) {
  return ref.watch(residentsProvider(condominiumId)).when(
    data: (residents) => residents,
    loading: () => [],
    error: (_, __) => [],
  );
});

final isLoadingResidentsProvider = Provider.family<bool, String>((ref, condominiumId) {
  return ref.watch(residentsProvider(condominiumId)).isLoading;
});