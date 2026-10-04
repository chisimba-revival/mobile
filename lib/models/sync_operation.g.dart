// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingOperation _$PendingOperationFromJson(Map<String, dynamic> json) =>
    _PendingOperation(
      operationId: json['operation_id'] as String,
      entityId: json['entity_id'] as String,
      entity: $enumDecode(_$EntityKindEnumMap, json['entity']),
      kind: $enumDecode(_$OperationKindEnumMap, json['kind']),
      baseRevision: (json['base_revision'] as num).toInt(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      dependsOn: json['depends_on'] as String?,
      payload: json['payload'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PendingOperationToJson(_PendingOperation instance) =>
    <String, dynamic>{
      'operation_id': instance.operationId,
      'entity_id': instance.entityId,
      'entity': _$EntityKindEnumMap[instance.entity]!,
      'kind': _$OperationKindEnumMap[instance.kind]!,
      'base_revision': instance.baseRevision,
      'captured_at': instance.capturedAt.toIso8601String(),
      'recorded_at': instance.recordedAt.toIso8601String(),
      'depends_on': instance.dependsOn,
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
  operationId: json['operation_id'] as String,
  outcome: $enumDecode(_$PushOutcomeEnumMap, json['outcome']),
  newRevision: (json['new_revision'] as num?)?.toInt(),
  errorCode: json['error_code'] as String?,
  serverState: json['server_state'] as Map<String, dynamic>?,
  serverRevision: (json['server_revision'] as num?)?.toInt(),
);

Map<String, dynamic> _$PushResultToJson(_PushResult instance) =>
    <String, dynamic>{
      'operation_id': instance.operationId,
      'outcome': _$PushOutcomeEnumMap[instance.outcome]!,
      'new_revision': instance.newRevision,
      'error_code': instance.errorCode,
      'server_state': instance.serverState,
      'server_revision': instance.serverRevision,
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
  nextCursor: json['next_cursor'] as String?,
  hasMore: json['has_more'] as bool,
  serverTime: DateTime.parse(json['server_time'] as String),
  status: json['status'] as String? ?? 'ok',
);

Map<String, dynamic> _$PullPageToJson(_PullPage instance) => <String, dynamic>{
  'changes': instance.changes,
  'next_cursor': instance.nextCursor,
  'has_more': instance.hasMore,
  'server_time': instance.serverTime.toIso8601String(),
  'status': instance.status,
};

_PullChange _$PullChangeFromJson(Map<String, dynamic> json) => _PullChange(
  entity: $enumDecode(_$EntityKindEnumMap, json['entity']),
  entityId: json['entity_id'] as String,
  revision: (json['revision'] as num).toInt(),
  isTombstone: json['is_tombstone'] as bool,
  state: json['state'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PullChangeToJson(_PullChange instance) =>
    <String, dynamic>{
      'entity': _$EntityKindEnumMap[instance.entity]!,
      'entity_id': instance.entityId,
      'revision': instance.revision,
      'is_tombstone': instance.isTombstone,
      'state': instance.state,
    };
