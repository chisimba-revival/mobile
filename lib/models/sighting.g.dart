// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sighting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WildlifeSighting _$WildlifeSightingFromJson(
  Map<String, dynamic> json,
) => _WildlifeSighting(
  id: json['id'] as String,
  contextCode: json['context_code'] as String,
  driveId: json['drive_id'] as String,
  status: $enumDecode(_$SightingStatusEnumMap, json['status']),
  location: const GeoPointConverter().fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  capturedAt: DateTime.parse(json['captured_at'] as String),
  recordedAt: DateTime.parse(json['recorded_at'] as String),
  revision: (json['revision'] as num).toInt(),
  createdBy: json['created_by'] as String,
  speciesCode: json['species_code'] as String?,
  count: (json['count'] as num?)?.toInt(),
  locationAccuracyM: (json['location_accuracy_m'] as num?)?.toDouble(),
  distanceM: (json['distance_m'] as num?)?.toInt(),
  bearingDeg: (json['bearing_deg'] as num?)?.toInt(),
  behaviour: $enumDecodeNullable(_$SightingBehaviourEnumMap, json['behaviour']),
  ageSexClass: $enumDecodeNullable(_$AgeSexClassEnumMap, json['age_sex_class']),
  notes: json['notes'] as String?,
  verifiedBy: json['verified_by'] as String?,
  verifiedAt: json['verified_at'] == null
      ? null
      : DateTime.parse(json['verified_at'] as String),
  verificationNotes: json['verification_notes'] as String?,
  recordedSpeciesCode: json['recorded_species_code'] as String?,
  recordedCount: (json['recorded_count'] as num?)?.toInt(),
  lateArrival: json['late_arrival'] as bool? ?? false,
);

Map<String, dynamic> _$WildlifeSightingToJson(_WildlifeSighting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'context_code': instance.contextCode,
      'drive_id': instance.driveId,
      'status': _$SightingStatusEnumMap[instance.status]!,
      'location': const GeoPointConverter().toJson(instance.location),
      'captured_at': instance.capturedAt.toIso8601String(),
      'recorded_at': instance.recordedAt.toIso8601String(),
      'revision': instance.revision,
      'created_by': instance.createdBy,
      'species_code': instance.speciesCode,
      'count': instance.count,
      'location_accuracy_m': instance.locationAccuracyM,
      'distance_m': instance.distanceM,
      'bearing_deg': instance.bearingDeg,
      'behaviour': _$SightingBehaviourEnumMap[instance.behaviour],
      'age_sex_class': _$AgeSexClassEnumMap[instance.ageSexClass],
      'notes': instance.notes,
      'verified_by': instance.verifiedBy,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'verification_notes': instance.verificationNotes,
      'recorded_species_code': instance.recordedSpeciesCode,
      'recorded_count': instance.recordedCount,
      'late_arrival': instance.lateArrival,
    };

const _$SightingStatusEnumMap = {
  SightingStatus.pending: 'pending',
  SightingStatus.verified: 'verified',
  SightingStatus.rejected: 'rejected',
  SightingStatus.needsReview: 'needs_review',
};

const _$SightingBehaviourEnumMap = {
  SightingBehaviour.grazing: 'grazing',
  SightingBehaviour.moving: 'moving',
  SightingBehaviour.resting: 'resting',
  SightingBehaviour.feeding: 'feeding',
  SightingBehaviour.withYoung: 'with_young',
  SightingBehaviour.alert: 'alert',
  SightingBehaviour.unknown: 'unknown',
};

const _$AgeSexClassEnumMap = {
  AgeSexClass.female: 'female',
  AgeSexClass.male: 'male',
  AgeSexClass.juvenile: 'juvenile',
  AgeSexClass.adultUnknown: 'adult_unknown',
  AgeSexClass.unknown: 'unknown',
};
