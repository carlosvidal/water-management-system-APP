import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';

class PeriodsNotifier extends StateNotifier<AsyncValue<List<Period>>> {
  final ApiService _apiService;
  final String condominiumId;

  PeriodsNotifier(this._apiService, this.condominiumId) : super(const AsyncValue.loading()) {
    loadPeriods();
  }

  Future<void> loadPeriods() async {
    try {
      state = const AsyncValue.loading();
      final periodsData = await _apiService.getCondominiumPeriods(condominiumId);
      final periods = periodsData.map((data) => Period.fromJson(data)).toList();
      periods.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
      state = AsyncValue.data(periods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Period> createPeriod({
    required DateTime startDate,
  }) async {
    try {
      // Ensure the date is in UTC and has the Z suffix for proper validation
      final utcDate = DateTime.utc(
        startDate.year,
        startDate.month, 
        startDate.day,
        startDate.hour,
        startDate.minute,
        startDate.second,
        startDate.millisecond,
      );
      
      final periodData = await _apiService.createPeriod(condominiumId, {
        'startDate': utcDate.toIso8601String(),
      });
      
      final newPeriod = Period.fromJson(periodData);
      
      // Add to current state
      final currentPeriods = state.value ?? [];
      final updatedPeriods = [newPeriod, ...currentPeriods];
      state = AsyncValue.data(updatedPeriods);
      
      return newPeriod;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePeriod(String periodId, Map<String, dynamic> updateData) async {
    try {
      final updatedPeriodData = await _apiService.updatePeriod(periodId, updateData);
      final updatedPeriod = Period.fromJson(updatedPeriodData);
      
      // Update in current state
      final currentPeriods = state.value ?? [];
      final updatedPeriods = currentPeriods.map((period) {
        return period.id == periodId ? updatedPeriod : period;
      }).toList();
      
      state = AsyncValue.data(updatedPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deletePeriod(String periodId) async {
    try {
      await _apiService.deletePeriod(periodId);
      
      // Remove from current state
      final currentPeriods = state.value ?? [];
      final updatedPeriods = currentPeriods.where((period) => period.id != periodId).toList();
      
      state = AsyncValue.data(updatedPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> closePeriod(String periodId) async {
    try {
      await _apiService.closePeriod(periodId);
      
      // Reload to get updated status
      await loadPeriods();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadPeriods();
  }

  Period? getCurrentPeriod() {
    final periods = state.value ?? [];
    try {
      return periods.firstWhere((period) => period.status == 'OPEN');
    } catch (e) {
      return null; // No open period found
    }
  }

  bool hasOpenPeriod() {
    return getCurrentPeriod() != null;
  }
}

// Provider factory for periods by condominium
final periodsProvider = StateNotifierProvider.family<PeriodsNotifier, AsyncValue<List<Period>>, String>(
  (ref, condominiumId) {
    final apiService = ref.watch(apiServiceProvider);
    return PeriodsNotifier(apiService, condominiumId);
  },
);

// Provider for current period of a condominium
final currentPeriodProvider = Provider.family<Period?, String>((ref, condominiumId) {
  final periodsAsync = ref.watch(periodsProvider(condominiumId));
  return periodsAsync.whenOrNull(
    data: (periods) {
      try {
        return periods.firstWhere((period) => period.status == 'OPEN');
      } catch (e) {
        return null;
      }
    },
  );
});

// Provider to check if condominium has an open period
final hasOpenPeriodProvider = Provider.family<bool, String>((ref, condominiumId) {
  final currentPeriod = ref.watch(currentPeriodProvider(condominiumId));
  return currentPeriod != null;
});