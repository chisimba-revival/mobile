// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sighting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WildlifeSighting _$WildlifeSightingFromJson(
  Map<String, dynamic> json,
) => _WildlifeSighting(
  id: json['id'] as String,
  contextCode: json['contextCode'] as String,
  driveId: json['driveId'] as String,
  status: $enumDecode(_$SightingStatusEnumMap, json['status']),
  location: const GeoPointConverter().fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  capturedAt: DateTime.parse(json['capturedAt'] as String),
  recordedAt: DateTime.parse(json['recordedAt'] as String),
  revision: (json['revision'] as num).toInt(),
  createdBy: json['createdBy'] as String,
  speciesCode: json['speciesCode'] as String?,
  count: (json['count'] as num?)?.toInt(),
  locationAccuracyM: (json['locationAccuracyM'] as num?)?.toDouble(),
  distanceM: (json['distanceM'] as num?)?.toInt(),
  bearingDeg: (json['bearingDeg'] as num?)?.toInt(),
  behaviour: $enumDecodeNullable(_$SightingBehaviourEnumMap, json['behaviour']),
  ageSexClass: $enumDecodeNullable(_$AgeSexClassEnumMap, json['ageSexClass']),
  notes: json['notes'] as String?,
  verifiedBy: json['verifiedBy'] as String?,
  verifiedAt: json['verifiedAt'] == null
      ? null
      : DateTime.parse(json['verifiedAt'] as String),
  verificationNotes: json['verificationNotes'] as String?,
  recordedSpeciesCode: json['recordedSpeciesCode'] as String?,
  recordedCount: (json['recordedCount'] as num?)?.toInt(),
  lateArrival: json['lateArrival'] as bool? ?? false,
);

Map<String, dynamic> _$WildlifeSightingToJson(_WildlifeSighting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contextCode': instance.contextCode,
      'driveId': instance.driveId,
      'status': _$SightingStatusEnumMap[instance.status]!,
      'location': const GeoPointConverter().toJson(instance.location),
      'capturedAt': instance.capturedAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'revision': instance.revision,
      'createdBy': instance.createdBy,
      'speciesCode': instance.speciesCode,
      'count': instance.count,
      'locationAccuracyM': instance.locationAccuracyM,
      'distanceM': instance.distanceM,
      'bearingDeg': instance.bearingDeg,
      'behaviour': _$SightingBehaviourEnumMap[instance.behaviour],
      'ageSexClass': _$AgeSexClassEnumMap[instance.ageSexClass],
      'notes': instance.notes,
      'verifiedBy': instance.verifiedBy,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'verificationNotes': instance.verificationNotes,
      'recordedSpeciesCode': instance.recordedSpeciesCode,
      'recordedCount': instance.recordedCount,
      'lateArrival': instance.lateArrival,
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
