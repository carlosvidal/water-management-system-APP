// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condominium.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Condominium _$CondominiumFromJson(Map<String, dynamic> json) => Condominium(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  city: json['city'] as String?,
  country: json['country'] as String?,
  readingDay: (json['readingDay'] as num?)?.toInt(),
  bankAccount: json['bankAccount'] as String?,
  bankAccountHolder: json['bankAccountHolder'] as String?,
  planId: json['planId'] as String?,
  totalUnitsPlanned: (json['totalUnitsPlanned'] as num?)?.toInt(),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  blocks:
      (json['blocks'] as List<dynamic>?)
          ?.map((e) => Block.fromJson(e as Map<String, dynamic>))
          .toList(),
  plan:
      json['plan'] == null
          ? null
          : Plan.fromJson(json['plan'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CondominiumToJson(Condominium instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'country': instance.country,
      'readingDay': instance.readingDay,
      'bankAccount': instance.bankAccount,
      'bankAccountHolder': instance.bankAccountHolder,
      'planId': instance.planId,
      'totalUnitsPlanned': instance.totalUnitsPlanned,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'blocks': instance.blocks,
      'plan': instance.plan,
    };

Block _$BlockFromJson(Map<String, dynamic> json) => Block(
  id: json['id'] as String,
  name: json['name'] as String,
  condominiumId: json['condominiumId'] as String,
  maxUnits: (json['maxUnits'] as num?)?.toInt(),
  units:
      (json['units'] as List<dynamic>?)
          ?.map((e) => Unit.fromJson(e as Map<String, dynamic>))
          .toList(),
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$BlockToJson(Block instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'condominiumId': instance.condominiumId,
  'maxUnits': instance.maxUnits,
  'units': instance.units,
  'createdAt': instance.createdAt?.toIso8601String(),
};

Unit _$UnitFromJson(Map<String, dynamic> json) => Unit(
  id: json['id'] as String,
  name: json['name'] as String,
  blockId: json['blockId'] as String?,
  residentId: json['residentId'] as String?,
  isActive: json['isActive'] as bool?,
  block:
      json['block'] == null
          ? null
          : Block.fromJson(json['block'] as Map<String, dynamic>),
  resident:
      json['resident'] == null
          ? null
          : Resident.fromJson(json['resident'] as Map<String, dynamic>),
  residents:
      (json['residents'] as List<dynamic>?)
          ?.map((e) => Resident.fromJson(e as Map<String, dynamic>))
          .toList(),
  meters:
      (json['meters'] as List<dynamic>?)
          ?.map((e) => Meter.fromJson(e as Map<String, dynamic>))
          .toList(),
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UnitToJson(Unit instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'blockId': instance.blockId,
  'residentId': instance.residentId,
  'isActive': instance.isActive,
  'block': instance.block,
  'resident': instance.resident,
  'residents': instance.residents,
  'meters': instance.meters,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

Meter _$MeterFromJson(Map<String, dynamic> json) => Meter(
  id: json['id'] as String,
  type: json['type'] as String,
  serialNumber: json['serialNumber'] as String?,
);

Map<String, dynamic> _$MeterToJson(Meter instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'serialNumber': instance.serialNumber,
};

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  id: json['id'] as String,
  name: json['name'] as String,
  pricePerUnitPEN: (json['pricePerUnitPEN'] as num).toDouble(),
  minimumUnits: (json['minimumUnits'] as num).toInt(),
  isAnnualPrepaid: json['isAnnualPrepaid'] as bool,
  features:
      (json['features'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'pricePerUnitPEN': instance.pricePerUnitPEN,
  'minimumUnits': instance.minimumUnits,
  'isAnnualPrepaid': instance.isAnnualPrepaid,
  'features': instance.features,
};

Period _$PeriodFromJson(Map<String, dynamic> json) => Period(
  id: json['id'] as String,
  condominiumId: json['condominiumId'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate:
      json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
  status: json['status'] as String,
  totalVolume: (json['totalVolume'] as num?)?.toDouble(),
  totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  receiptPhoto1: json['receiptPhoto1'] as String?,
  receiptPhoto2: json['receiptPhoto2'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PeriodToJson(Period instance) => <String, dynamic>{
  'id': instance.id,
  'condominiumId': instance.condominiumId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'status': instance.status,
  'totalVolume': instance.totalVolume,
  'totalAmount': instance.totalAmount,
  'receiptPhoto1': instance.receiptPhoto1,
  'receiptPhoto2': instance.receiptPhoto2,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
