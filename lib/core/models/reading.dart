import 'package:json_annotation/json_annotation.dart';

part 'reading.g.dart';

@JsonSerializable()
class Reading {
  final String id;
  final String unitId;
  final String periodId;
  final double value;
  final double? previousValue;
  final double? consumption;
  final String? photo1Path;
  final String? photo2Path;
  final String? notes;
  final bool isAnomalous;
  final bool isValidated;
  final bool isSynced;
  final DateTime readingDate;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  
  const Reading({
    required this.id,
    required this.unitId,
    required this.periodId,
    required this.value,
    this.previousValue,
    this.consumption,
    this.photo1Path,
    this.photo2Path,
    this.notes,
    required this.isAnomalous,
    required this.isValidated,
    this.isSynced = false,
    required this.readingDate,
    required this.createdAt,
    this.validatedAt,
    this.validatedBy,
  });

  factory Reading.fromJson(Map<String, dynamic> json) => _$ReadingFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReadingToJson(this);

  Reading copyWith({
    String? id,
    String? unitId,
    String? periodId,
    double? value,
    double? previousValue,
    double? consumption,
    String? photo1Path,
    String? photo2Path,
    String? notes,
    bool? isAnomalous,
    bool? isValidated,
    bool? isSynced,
    DateTime? readingDate,
    DateTime? createdAt,
    DateTime? validatedAt,
    String? validatedBy,
  }) {
    return Reading(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      periodId: periodId ?? this.periodId,
      value: value ?? this.value,
      previousValue: previousValue ?? this.previousValue,
      consumption: consumption ?? this.consumption,
      photo1Path: photo1Path ?? this.photo1Path,
      photo2Path: photo2Path ?? this.photo2Path,
      notes: notes ?? this.notes,
      isAnomalous: isAnomalous ?? this.isAnomalous,
      isValidated: isValidated ?? this.isValidated,
      isSynced: isSynced ?? this.isSynced,
      readingDate: readingDate ?? this.readingDate,
      createdAt: createdAt ?? this.createdAt,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedBy: validatedBy ?? this.validatedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reading && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Period {
  final String id;
  final String name;
  final String condominiumId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Reading>? readings;
  
  const Period({
    required this.id,
    required this.name,
    required this.condominiumId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.readings,
  });

  factory Period.fromJson(Map<String, dynamic> json) => _$PeriodFromJson(json);
  
  Map<String, dynamic> toJson() => _$PeriodToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Period && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class OCRResult {
  final double? extractedValue;
  final double confidence;
  final String rawText;
  final List<double>? alternativeValues;
  
  const OCRResult({
    this.extractedValue,
    required this.confidence,
    required this.rawText,
    this.alternativeValues,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) => _$OCRResultFromJson(json);
  
  Map<String, dynamic> toJson() => _$OCRResultToJson(this);
}