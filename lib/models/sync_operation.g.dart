// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingOperation _$PendingOperationFromJson(Map<String, dynamic> json) =>
    _PendingOperation(
      operationId: json['operationId'] as String,
      entityId: json['entityId'] as String,
      entity: $enumDecode(_$EntityKindEnumMap, json['entity']),
      kind: $enumDecode(_$OperationKindEnumMap, json['kind']),
      baseRevision: (json['baseRevision'] as num).toInt(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      dependsOn: json['dependsOn'] as String?,
      payload: json['payload'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PendingOperationToJson(_PendingOperation instance) =>
    <String, dynamic>{
      'operationId': instance.operationId,
      'entityId': instance.entityId,
      'entity': _$EntityKindEnumMap[instance.entity]!,
      'kind': _$OperationKindEnumMap[instance.kind]!,
      'baseRevision': instance.baseRevision,
      'capturedAt': instance.capturedAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'dependsOn': instance.dependsOn,
      'payload': instance.payload,
    };

const _$EntityKindEnumMap = {
  EntityKind.drive: 'drive',
  EntityKind.trailLog: 'trail_log',
  EntityKind.sighting: 'sighting',
  EntityKind.signOff: 'sign_off',
  EntityKind.media: 'media',
};

const _$OperationKindEnumMap = {
  OperationKind.create: 'create',
  OperationKind.update: 'update',
  OperationKind.delete: 'delete',
  OperationKind.start: 'start',
  OperationKind.end: 'end',
  OperationKind.verify: 'verify',
};

_PushResult _$PushResultFromJson(Map<String, dynamic> json) => _PushResult(
  operationId: json['operationId'] as String,
  outcome: $enumDecode(_$PushOutcomeEnumMap, json['outcome']),
  newRevision: (json['newRevision'] as num?)?.toInt(),
  errorCode: json['errorCode'] as String?,
  serverState: json['serverState'] as Map<String, dynamic>?,
  serverRevision: (json['serverRevision'] as num?)?.toInt(),
);

Map<String, dynamic> _$PushResultToJson(_PushResult instance) =>
    <String, dynamic>{
      'operationId': instance.operationId,
      'outcome': _$PushOutcomeEnumMap[instance.outcome]!,
      'newRevision': instance.newRevision,
      'errorCode': instance.errorCode,
      'serverState': instance.serverState,
      'serverRevision': instance.serverRevision,
    };

const _$PushOutcomeEnumMap = {
  PushOutcome.applied: 'applied',
  PushOutcome.noop: 'noop',
  PushOutcome.deferred: 'deferred',
  PushOutcome.refused: 'refused',
};

_PullPage _$PullPageFromJson(Map<String, dynamic> json) => _PullPage(
  changes: (json['changes'] as List<dynamic>)
      .map((e) => PullChange.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
  hasMore: json['hasMore'] as bool,
  serverTime: DateTime.parse(json['serverTime'] as String),
);

Map<String, dynamic> _$PullPageToJson(_PullPage instance) => <String, dynamic>{
  'changes': instance.changes,
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
  'serverTime': instance.serverTime.toIso8601String(),
};

_PullChange _$PullChangeFromJson(Map<String, dynamic> json) => _PullChange(
  entity: $enumDecode(_$EntityKindEnumMap, json['entity']),
  entityId: json['entityId'] as String,
  revision: (json['revision'] as num).toInt(),
  isTombstone: json['isTombstone'] as bool,
  state: json['state'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PullChangeToJson(_PullChange instance) =>
    <String, dynamic>{
      'entity': _$EntityKindEnumMap[instance.entity]!,
      'entityId': instance.entityId,
      'revision': instance.revision,
      'isTombstone': instance.isTombstone,
      'state': instance.state,
    };
