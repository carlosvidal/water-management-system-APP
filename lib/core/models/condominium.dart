import 'package:json_annotation/json_annotation.dart';

part 'condominium.g.dart';

@JsonSerializable()
class Condominium {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? country;
  final int? readingDay;
  final String? bankAccount;
  final String? bankAccountHolder;
  final String? planId;
  final int? totalUnitsPlanned;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Block>? blocks;
  final Plan? plan;
  
  const Condominium({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.country,
    this.readingDay,
    this.bankAccount,
    this.bankAccountHolder,
    this.planId,
    this.totalUnitsPlanned,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.blocks,
    this.plan,
  });

  factory Condominium.fromJson(Map<String, dynamic> json) {
    try {
      return _$CondominiumFromJson(json);
    } catch (e) {
      // Error parsing Condominium data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$CondominiumToJson(this);

  Condominium copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? country,
    int? readingDay,
    String? bankAccount,
    String? bankAccountHolder,
    String? planId,
    int? totalUnitsPlanned,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Block>? blocks,
  }) {
    return Condominium(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      readingDay: readingDay ?? this.readingDay,
      bankAccount: bankAccount ?? this.bankAccount,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      planId: planId ?? this.planId,
      totalUnitsPlanned: totalUnitsPlanned ?? this.totalUnitsPlanned,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Condominium && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Block {
  final String id;
  final String name;
  final String condominiumId;
  final int? maxUnits;
  final List<Unit>? units;
  final DateTime? createdAt;
  
  const Block({
    required this.id,
    required this.name,
    required this.condominiumId,
    this.maxUnits,
    this.units,
    this.createdAt,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    try {
      return _$BlockFromJson(json);
    } catch (e) {
      // Error parsing Block data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$BlockToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Block && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Unit {
  final String id;
  final String name;
  final String? blockId;
  final String? residentId;
  final bool? isActive;
  final Block? block;
  final Resident? resident;
  final List<Resident>? residents;
  final List<Meter>? meters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Unit({
    required this.id,
    required this.name,
    this.blockId,
    this.residentId,
    this.isActive,
    this.block,
    this.resident,
    this.residents,
    this.meters,
    this.createdAt,
    this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    try {
      return _$UnitFromJson(json);
    } catch (e) {
      // Error parsing Unit data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$UnitToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Resident {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String condominiumId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const Resident({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.condominiumId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Resident.fromJson(Map<String, dynamic> json) {
    try {
      return Resident(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        condominiumId: json['condominiumId'] as String? ?? 'unknown', // Fallback for nested residents
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      );
    } catch (e) {
      // Error parsing Resident data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'condominiumId': condominiumId,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resident && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Meter {
  final String id;
  final String type;
  final String? serialNumber;
  
  const Meter({
    required this.id,
    required this.type,
    this.serialNumber,
  });

  factory Meter.fromJson(Map<String, dynamic> json) {
    try {
      return _$MeterFromJson(json);
    } catch (e) {
      // Error parsing Meter data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$MeterToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Plan {
  final String id;
  final String name;
  final double pricePerUnitPEN;
  final int minimumUnits;
  final bool isAnnualPrepaid;
  final List<String>? features;
  
  const Plan({
    required this.id,
    required this.name,
    required this.pricePerUnitPEN,
    required this.minimumUnits,
    required this.isAnnualPrepaid,
    this.features,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    try {
      return _$PlanFromJson(json);
    } catch (e) {
      // Error parsing Plan data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$PlanToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plan && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Period {
  final String id;
  final String condominiumId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // OPEN, PENDING_RECEIPT, CALCULATING, CLOSED
  final double? totalVolume;
  final double? totalAmount;
  final String? receiptPhoto1;
  final String? receiptPhoto2;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Period({
    required this.id,
    required this.condominiumId,
    required this.startDate,
    this.endDate,
    required this.status,
    this.totalVolume,
    this.totalAmount,
    this.receiptPhoto1,
    this.receiptPhoto2,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    try {
      return _$PeriodFromJson(json);
    } catch (e) {
      // Error parsing Period data
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$PeriodToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Period && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

