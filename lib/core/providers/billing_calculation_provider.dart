import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingCalculationState {
  final String? totalVolume;
  final String? totalAmount;
  final String? periodId;

  const BillingCalculationState({
    this.totalVolume,
    this.totalAmount,
    this.periodId,
  });

  BillingCalculationState copyWith({
    String? totalVolume,
    String? totalAmount,
    String? periodId,
  }) {
    return BillingCalculationState(
      totalVolume: totalVolume ?? this.totalVolume,
      totalAmount: totalAmount ?? this.totalAmount,
      periodId: periodId ?? this.periodId,
    );
  }
}

class BillingCalculationNotifier extends StateNotifier<BillingCalculationState> {
  BillingCalculationNotifier() : super(const BillingCalculationState());

  void updateBillingData(String periodId, String? totalVolume, String? totalAmount) {
    state = state.copyWith(
      periodId: periodId,
      totalVolume: totalVolume,
      totalAmount: totalAmount,
    );
  }

  void clearBillingData() {
    state = const BillingCalculationState();
  }

  BillingCalculationState? getBillingDataForPeriod(String periodId) {
    if (state.periodId == periodId) {
      return state;
    }
    return null;
  }
}

final billingCalculationProvider = StateNotifierProvider<BillingCalculationNotifier, BillingCalculationState>(
  (ref) => BillingCalculationNotifier(),
);