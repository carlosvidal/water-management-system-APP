// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reading _$ReadingFromJson(Map<String, dynamic> json) => Reading(
  id: json['id'] as String,
  unitId: json['unitId'] as String,
  periodId: json['periodId'] as String,
  value: (json['value'] as num).toDouble(),
  previousValue: (json['previousValue'] as num?)?.toDouble(),
  consumption: (json['consumption'] as num?)?.toDouble(),
  photo1Path: json['photo1Path'] as String?,
  photo2Path: json['photo2Path'] as String?,
  notes: json['notes'] as String?,
  isAnomalous: json['isAnomalous'] as bool,
  isValidated: json['isValidated'] as bool,
  isSynced: json['isSynced'] as bool? ?? false,
  readingDate: DateTime.parse(json['readingDate'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  validatedAt:
      json['validatedAt'] == null
          ? null
          : DateTime.parse(json['validatedAt'] as String),
  validatedBy: json['validatedBy'] as String?,
);

Map<String, dynamic> _$ReadingToJson(Reading instance) => <String, dynamic>{
  'id': instance.id,
  'unitId': instance.unitId,
  'periodId': instance.periodId,
  'value': instance.value,
  'previousValue': instance.previousValue,
  'consumption': instance.consumption,
  'photo1Path': instance.photo1Path,
  'photo2Path': instance.photo2Path,
  'notes': instance.notes,
  'isAnomalous': instance.isAnomalous,
  'isValidated': instance.isValidated,
  'isSynced': instance.isSynced,
  'readingDate': instance.readingDate.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'validatedAt': instance.validatedAt?.toIso8601String(),
  'validatedBy': instance.validatedBy,
};

Period _$PeriodFromJson(Map<String, dynamic> json) => Period(
  id: json['id'] as String,
  name: json['name'] as String,
  condominiumId: json['condominiumId'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  readings:
      (json['readings'] as List<dynamic>?)
          ?.map((e) => Reading.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$PeriodToJson(Period instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'condominiumId': instance.condominiumId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'readings': instance.readings,
};

OCRResult _$OCRResultFromJson(Map<String, dynamic> json) => OCRResult(
  extractedValue: (json['extractedValue'] as num?)?.toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
  rawText: json['rawText'] as String,
  alternativeValues:
      (json['alternativeValues'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
);

Map<String, dynamic> _$OCRResultToJson(OCRResult instance) => <String, dynamic>{
  'extractedValue': instance.extractedValue,
  'confidence': instance.confidence,
  'rawText': instance.rawText,
  'alternativeValues': instance.alternativeValues,
};
