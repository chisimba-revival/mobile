// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingOperation {

 String get operationId;/// Device-generated entity id. A client mints its own ids from the start,
/// so that a queued operation can name its subject before the service has
/// ever heard of it.
 String get entityId; EntityKind get entity; OperationKind get kind; int get baseRevision; DateTime get capturedAt; DateTime get recordedAt; String? get dependsOn; Map<String, dynamic> get payload;
/// Create a copy of PendingOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingOperationCopyWith<PendingOperation> get copyWith => _$PendingOperationCopyWithImpl<PendingOperation>(this as PendingOperation, _$identity);

  /// Serializes this PendingOperation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PendingOperation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingOperation&&(identical(other.operationId, _this.operationId) || other.operationId == _this.operationId)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.entity, _this.entity) || other.entity == _this.entity)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.baseRevision, _this.baseRevision) || other.baseRevision == _this.baseRevision)&&(identical(other.capturedAt, _this.capturedAt) || other.capturedAt == _this.capturedAt)&&(identical(other.recordedAt, _this.recordedAt) || other.recordedAt == _this.recordedAt)&&(identical(other.dependsOn, _this.dependsOn) || other.dependsOn == _this.dependsOn)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PendingOperation;
  return Object.hash(runtimeType,_this.operationId,_this.entityId,_this.entity,_this.kind,_this.baseRevision,_this.capturedAt,_this.recordedAt,_this.dependsOn,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as PendingOperation;
  return 'PendingOperation(operationId: ${_this.operationId}, entityId: ${_this.entityId}, entity: ${_this.entity}, kind: ${_this.kind}, baseRevision: ${_this.baseRevision}, capturedAt: ${_this.capturedAt}, recordedAt: ${_this.recordedAt}, dependsOn: ${_this.dependsOn}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $PendingOperationCopyWith<$Res>  {
  factory $PendingOperationCopyWith(PendingOperation value, $Res Function(PendingOperation) _then) = _$PendingOperationCopyWithImpl;
@useResult
$Res call({
 String operationId, String entityId, EntityKind entity, OperationKind kind, int baseRevision, DateTime capturedAt, DateTime recordedAt, String? dependsOn, Map<String, dynamic> payload
});




}
/// @nodoc
class _$PendingOperationCopyWithImpl<$Res>
    implements $PendingOperationCopyWith<$Res> {
  _$PendingOperationCopyWithImpl(this._self, this._then);

  final PendingOperation _self;
  final $Res Function(PendingOperation) _then;

/// Create a copy of PendingOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operationId = null,Object? entityId = null,Object? entity = null,Object? kind = null,Object? baseRevision = null,Object? capturedAt = null,Object? recordedAt = null,Object? dependsOn = freezed,Object? payload = null,}) {
  return _then(PendingOperation(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as EntityKind,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OperationKind,baseRevision: null == baseRevision ? _self.baseRevision : baseRevision // ignore: cast_nullable_to_non_nullable
as int,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dependsOn: freezed == dependsOn ? _self.dependsOn : dependsOn // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingOperation].
extension PendingOperationPatterns on PendingOperation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingOperation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingOperation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingOperation value)  $default,){
final _that = this;
switch (_that) {
case _PendingOperation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingOperation value)?  $default,){
final _that = this;
switch (_that) {
case _PendingOperation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String operationId,  String entityId,  EntityKind entity,  OperationKind kind,  int baseRevision,  DateTime capturedAt,  DateTime recordedAt,  String? dependsOn,  Map<String, dynamic> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingOperation() when $default != null:
return $default(_that.operationId,_that.entityId,_that.entity,_that.kind,_that.baseRevision,_that.capturedAt,_that.recordedAt,_that.dependsOn,_that.payload);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String operationId,  String entityId,  EntityKind entity,  OperationKind kind,  int baseRevision,  DateTime capturedAt,  DateTime recordedAt,  String? dependsOn,  Map<String, dynamic> payload)  $default,) {final _that = this;
switch (_that) {
case _PendingOperation():
return $default(_that.operationId,_that.entityId,_that.entity,_that.kind,_that.baseRevision,_that.capturedAt,_that.recordedAt,_that.dependsOn,_that.payload);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String operationId,  String entityId,  EntityKind entity,  OperationKind kind,  int baseRevision,  DateTime capturedAt,  DateTime recordedAt,  String? dependsOn,  Map<String, dynamic> payload)?  $default,) {final _that = this;
switch (_that) {
case _PendingOperation() when $default != null:
return $default(_that.operationId,_that.entityId,_that.entity,_that.kind,_that.baseRevision,_that.capturedAt,_that.recordedAt,_that.dependsOn,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingOperation extends PendingOperation {
  const _PendingOperation({required this.operationId, required this.entityId, required this.entity, required this.kind, required this.baseRevision, required this.capturedAt, required this.recordedAt, this.dependsOn, required  Map<String, dynamic> payload}): _payload = payload,super._();
  factory _PendingOperation.fromJson(Map<String, dynamic> json) => _$PendingOperationFromJson(json);

@override final  String operationId;
/// Device-generated entity id. A client mints its own ids from the start,
/// so that a queued operation can name its subject before the service has
/// ever heard of it.
@override final  String entityId;
@override final  EntityKind entity;
@override final  OperationKind kind;
@override final  int baseRevision;
@override final  DateTime capturedAt;
@override final  DateTime recordedAt;
@override final  String? dependsOn;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of PendingOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingOperationCopyWith<_PendingOperation> get copyWith => __$PendingOperationCopyWithImpl<_PendingOperation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingOperationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingOperation&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.baseRevision, baseRevision) || other.baseRevision == baseRevision)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.dependsOn, dependsOn) || other.dependsOn == dependsOn)&&const DeepCollectionEquality().equals(other.payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,operationId,entityId,entity,kind,baseRevision,capturedAt,recordedAt,dependsOn,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'PendingOperation(operationId: $operationId, entityId: $entityId, entity: $entity, kind: $kind, baseRevision: $baseRevision, capturedAt: $capturedAt, recordedAt: $recordedAt, dependsOn: $dependsOn, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$PendingOperationCopyWith<$Res> implements $PendingOperationCopyWith<$Res> {
  factory _$PendingOperationCopyWith(_PendingOperation value, $Res Function(_PendingOperation) _then) = __$PendingOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, String entityId, EntityKind entity, OperationKind kind, int baseRevision, DateTime capturedAt, DateTime recordedAt, String? dependsOn, Map<String, dynamic> payload
});




}
/// @nodoc
class __$PendingOperationCopyWithImpl<$Res>
    implements _$PendingOperationCopyWith<$Res> {
  __$PendingOperationCopyWithImpl(this._self, this._then);

  final _PendingOperation _self;
  final $Res Function(_PendingOperation) _then;

/// Create a copy of PendingOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? entityId = null,Object? entity = null,Object? kind = null,Object? baseRevision = null,Object? capturedAt = null,Object? recordedAt = null,Object? dependsOn = freezed,Object? payload = null,}) {
  return _then(_PendingOperation(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as EntityKind,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OperationKind,baseRevision: null == baseRevision ? _self.baseRevision : baseRevision // ignore: cast_nullable_to_non_nullable
as int,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dependsOn: freezed == dependsOn ? _self.dependsOn : dependsOn // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$PushResult {

 String get operationId; PushOutcome get outcome; int? get newRevision; String? get errorCode; Map<String, dynamic>? get serverState; int? get serverRevision;
/// Create a copy of PushResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushResultCopyWith<PushResult> get copyWith => _$PushResultCopyWithImpl<PushResult>(this as PushResult, _$identity);

  /// Serializes this PushResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PushResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushResult&&(identical(other.operationId, _this.operationId) || other.operationId == _this.operationId)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.newRevision, _this.newRevision) || other.newRevision == _this.newRevision)&&(identical(other.errorCode, _this.errorCode) || other.errorCode == _this.errorCode)&&const DeepCollectionEquality().equals(other.serverState, _this.serverState)&&(identical(other.serverRevision, _this.serverRevision) || other.serverRevision == _this.serverRevision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PushResult;
  return Object.hash(runtimeType,_this.operationId,_this.outcome,_this.newRevision,_this.errorCode,const DeepCollectionEquality().hash(_this.serverState),_this.serverRevision);
}

@override
String toString() {
  final _this = this as PushResult;
  return 'PushResult(operationId: ${_this.operationId}, outcome: ${_this.outcome}, newRevision: ${_this.newRevision}, errorCode: ${_this.errorCode}, serverState: ${_this.serverState}, serverRevision: ${_this.serverRevision})';
}


}

/// @nodoc
abstract mixin class $PushResultCopyWith<$Res>  {
  factory $PushResultCopyWith(PushResult value, $Res Function(PushResult) _then) = _$PushResultCopyWithImpl;
@useResult
$Res call({
 String operationId, PushOutcome outcome, int? newRevision, String? errorCode, Map<String, dynamic>? serverState, int? serverRevision
});




}
/// @nodoc
class _$PushResultCopyWithImpl<$Res>
    implements $PushResultCopyWith<$Res> {
  _$PushResultCopyWithImpl(this._self, this._then);

  final PushResult _self;
  final $Res Function(PushResult) _then;

/// Create a copy of PushResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operationId = null,Object? outcome = null,Object? newRevision = freezed,Object? errorCode = freezed,Object? serverState = freezed,Object? serverRevision = freezed,}) {
  return _then(PushResult(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as PushOutcome,newRevision: freezed == newRevision ? _self.newRevision : newRevision // ignore: cast_nullable_to_non_nullable
as int?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,serverState: freezed == serverState ? _self.serverState : serverState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,serverRevision: freezed == serverRevision ? _self.serverRevision : serverRevision // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushResult].
extension PushResultPatterns on PushResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushResult value)  $default,){
final _that = this;
switch (_that) {
case _PushResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushResult value)?  $default,){
final _that = this;
switch (_that) {
case _PushResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String operationId,  PushOutcome outcome,  int? newRevision,  String? errorCode,  Map<String, dynamic>? serverState,  int? serverRevision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushResult() when $default != null:
return $default(_that.operationId,_that.outcome,_that.newRevision,_that.errorCode,_that.serverState,_that.serverRevision);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String operationId,  PushOutcome outcome,  int? newRevision,  String? errorCode,  Map<String, dynamic>? serverState,  int? serverRevision)  $default,) {final _that = this;
switch (_that) {
case _PushResult():
return $default(_that.operationId,_that.outcome,_that.newRevision,_that.errorCode,_that.serverState,_that.serverRevision);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String operationId,  PushOutcome outcome,  int? newRevision,  String? errorCode,  Map<String, dynamic>? serverState,  int? serverRevision)?  $default,) {final _that = this;
switch (_that) {
case _PushResult() when $default != null:
return $default(_that.operationId,_that.outcome,_that.newRevision,_that.errorCode,_that.serverState,_that.serverRevision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushResult extends PushResult {
  const _PushResult({required this.operationId, required this.outcome, this.newRevision, this.errorCode,  Map<String, dynamic>? serverState, this.serverRevision}): _serverState = serverState,super._();
  factory _PushResult.fromJson(Map<String, dynamic> json) => _$PushResultFromJson(json);

@override final  String operationId;
@override final  PushOutcome outcome;
@override final  int? newRevision;
@override final  String? errorCode;
 final  Map<String, dynamic>? _serverState;
@override Map<String, dynamic>? get serverState {
  final value = _serverState;
  if (value == null) return null;
  if (_serverState is EqualUnmodifiableMapView) return _serverState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  int? serverRevision;

/// Create a copy of PushResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushResultCopyWith<_PushResult> get copyWith => __$PushResultCopyWithImpl<_PushResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushResult&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.newRevision, newRevision) || other.newRevision == newRevision)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&const DeepCollectionEquality().equals(other.serverState, _serverState)&&(identical(other.serverRevision, serverRevision) || other.serverRevision == serverRevision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,operationId,outcome,newRevision,errorCode,const DeepCollectionEquality().hash(_serverState),serverRevision);
}

@override
String toString() {
    return 'PushResult(operationId: $operationId, outcome: $outcome, newRevision: $newRevision, errorCode: $errorCode, serverState: $serverState, serverRevision: $serverRevision)';
}


}

/// @nodoc
abstract mixin class _$PushResultCopyWith<$Res> implements $PushResultCopyWith<$Res> {
  factory _$PushResultCopyWith(_PushResult value, $Res Function(_PushResult) _then) = __$PushResultCopyWithImpl;
@override @useResult
$Res call({
 String operationId, PushOutcome outcome, int? newRevision, String? errorCode, Map<String, dynamic>? serverState, int? serverRevision
});




}
/// @nodoc
class __$PushResultCopyWithImpl<$Res>
    implements _$PushResultCopyWith<$Res> {
  __$PushResultCopyWithImpl(this._self, this._then);

  final _PushResult _self;
  final $Res Function(_PushResult) _then;

/// Create a copy of PushResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? outcome = null,Object? newRevision = freezed,Object? errorCode = freezed,Object? serverState = freezed,Object? serverRevision = freezed,}) {
  return _then(_PushResult(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as PushOutcome,newRevision: freezed == newRevision ? _self.newRevision : newRevision // ignore: cast_nullable_to_non_nullable
as int?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,serverState: freezed == serverState ? _self._serverState : serverState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,serverRevision: freezed == serverRevision ? _self.serverRevision : serverRevision // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PullPage {

 List<PullChange> get changes; String? get nextCursor; bool get hasMore; DateTime get serverTime; String get status;
/// Create a copy of PullPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PullPageCopyWith<PullPage> get copyWith => _$PullPageCopyWithImpl<PullPage>(this as PullPage, _$identity);

  /// Serializes this PullPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PullPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PullPage&&const DeepCollectionEquality().equals(other.changes, _this.changes)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PullPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.changes),_this.nextCursor,_this.hasMore,_this.serverTime,_this.status);
}

@override
String toString() {
  final _this = this as PullPage;
  return 'PullPage(changes: ${_this.changes}, nextCursor: ${_this.nextCursor}, hasMore: ${_this.hasMore}, serverTime: ${_this.serverTime}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $PullPageCopyWith<$Res>  {
  factory $PullPageCopyWith(PullPage value, $Res Function(PullPage) _then) = _$PullPageCopyWithImpl;
@useResult
$Res call({
 List<PullChange> changes, String? nextCursor, bool hasMore, DateTime serverTime, String status
});




}
/// @nodoc
class _$PullPageCopyWithImpl<$Res>
    implements $PullPageCopyWith<$Res> {
  _$PullPageCopyWithImpl(this._self, this._then);

  final PullPage _self;
  final $Res Function(PullPage) _then;

/// Create a copy of PullPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? changes = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,Object? status = null,}) {
  return _then(PullPage(
changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<PullChange>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PullPage].
extension PullPagePatterns on PullPage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PullPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PullPage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PullPage value)  $default,){
final _that = this;
switch (_that) {
case _PullPage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PullPage value)?  $default,){
final _that = this;
switch (_that) {
case _PullPage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PullChange> changes,  String? nextCursor,  bool hasMore,  DateTime serverTime,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PullPage() when $default != null:
return $default(_that.changes,_that.nextCursor,_that.hasMore,_that.serverTime,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PullChange> changes,  String? nextCursor,  bool hasMore,  DateTime serverTime,  String status)  $default,) {final _that = this;
switch (_that) {
case _PullPage():
return $default(_that.changes,_that.nextCursor,_that.hasMore,_that.serverTime,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PullChange> changes,  String? nextCursor,  bool hasMore,  DateTime serverTime,  String status)?  $default,) {final _that = this;
switch (_that) {
case _PullPage() when $default != null:
return $default(_that.changes,_that.nextCursor,_that.hasMore,_that.serverTime,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PullPage extends PullPage {
  const _PullPage({required  List<PullChange> changes, this.nextCursor, required this.hasMore, required this.serverTime, this.status = 'ok'}): _changes = changes,super._();
  factory _PullPage.fromJson(Map<String, dynamic> json) => _$PullPageFromJson(json);

 final  List<PullChange> _changes;
@override List<PullChange> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

@override final  String? nextCursor;
@override final  bool hasMore;
@override final  DateTime serverTime;
@override@JsonKey() final  String status;

/// Create a copy of PullPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullPageCopyWith<_PullPage> get copyWith => __$PullPageCopyWithImpl<_PullPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PullPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullPage&&const DeepCollectionEquality().equals(other.changes, _changes)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_changes),nextCursor,hasMore,serverTime,status);
}

@override
String toString() {
    return 'PullPage(changes: $changes, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PullPageCopyWith<$Res> implements $PullPageCopyWith<$Res> {
  factory _$PullPageCopyWith(_PullPage value, $Res Function(_PullPage) _then) = __$PullPageCopyWithImpl;
@override @useResult
$Res call({
 List<PullChange> changes, String? nextCursor, bool hasMore, DateTime serverTime, String status
});




}
/// @nodoc
class __$PullPageCopyWithImpl<$Res>
    implements _$PullPageCopyWith<$Res> {
  __$PullPageCopyWithImpl(this._self, this._then);

  final _PullPage _self;
  final $Res Function(_PullPage) _then;

/// Create a copy of PullPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? changes = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,Object? status = null,}) {
  return _then(_PullPage(
changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<PullChange>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PullChange {

 EntityKind get entity; String get entityId; int get revision; bool get isTombstone; Map<String, dynamic>? get state;
/// Create a copy of PullChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PullChangeCopyWith<PullChange> get copyWith => _$PullChangeCopyWithImpl<PullChange>(this as PullChange, _$identity);

  /// Serializes this PullChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PullChange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PullChange&&(identical(other.entity, _this.entity) || other.entity == _this.entity)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.isTombstone, _this.isTombstone) || other.isTombstone == _this.isTombstone)&&const DeepCollectionEquality().equals(other.state, _this.state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PullChange;
  return Object.hash(runtimeType,_this.entity,_this.entityId,_this.revision,_this.isTombstone,const DeepCollectionEquality().hash(_this.state));
}

@override
String toString() {
  final _this = this as PullChange;
  return 'PullChange(entity: ${_this.entity}, entityId: ${_this.entityId}, revision: ${_this.revision}, isTombstone: ${_this.isTombstone}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $PullChangeCopyWith<$Res>  {
  factory $PullChangeCopyWith(PullChange value, $Res Function(PullChange) _then) = _$PullChangeCopyWithImpl;
@useResult
$Res call({
 EntityKind entity, String entityId, int revision, bool isTombstone, Map<String, dynamic>? state
});




}
/// @nodoc
class _$PullChangeCopyWithImpl<$Res>
    implements $PullChangeCopyWith<$Res> {
  _$PullChangeCopyWithImpl(this._self, this._then);

  final PullChange _self;
  final $Res Function(PullChange) _then;

/// Create a copy of PullChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entity = null,Object? entityId = null,Object? revision = null,Object? isTombstone = null,Object? state = freezed,}) {
  return _then(PullChange(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as EntityKind,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,isTombstone: null == isTombstone ? _self.isTombstone : isTombstone // ignore: cast_nullable_to_non_nullable
as bool,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PullChange].
extension PullChangePatterns on PullChange {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PullChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PullChange() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PullChange value)  $default,){
final _that = this;
switch (_that) {
case _PullChange():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PullChange value)?  $default,){
final _that = this;
switch (_that) {
case _PullChange() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntityKind entity,  String entityId,  int revision,  bool isTombstone,  Map<String, dynamic>? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PullChange() when $default != null:
return $default(_that.entity,_that.entityId,_that.revision,_that.isTombstone,_that.state);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntityKind entity,  String entityId,  int revision,  bool isTombstone,  Map<String, dynamic>? state)  $default,) {final _that = this;
switch (_that) {
case _PullChange():
return $default(_that.entity,_that.entityId,_that.revision,_that.isTombstone,_that.state);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntityKind entity,  String entityId,  int revision,  bool isTombstone,  Map<String, dynamic>? state)?  $default,) {final _that = this;
switch (_that) {
case _PullChange() when $default != null:
return $default(_that.entity,_that.entityId,_that.revision,_that.isTombstone,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PullChange extends PullChange {
  const _PullChange({required this.entity, required this.entityId, required this.revision, required this.isTombstone,  Map<String, dynamic>? state}): _state = state,super._();
  factory _PullChange.fromJson(Map<String, dynamic> json) => _$PullChangeFromJson(json);

@override final  EntityKind entity;
@override final  String entityId;
@override final  int revision;
@override final  bool isTombstone;
 final  Map<String, dynamic>? _state;
@override Map<String, dynamic>? get state {
  final value = _state;
  if (value == null) return null;
  if (_state is EqualUnmodifiableMapView) return _state;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PullChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullChangeCopyWith<_PullChange> get copyWith => __$PullChangeCopyWithImpl<_PullChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PullChangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullChange&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.isTombstone, isTombstone) || other.isTombstone == isTombstone)&&const DeepCollectionEquality().equals(other.state, _state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,entity,entityId,revision,isTombstone,const DeepCollectionEquality().hash(_state));
}

@override
String toString() {
    return 'PullChange(entity: $entity, entityId: $entityId, revision: $revision, isTombstone: $isTombstone, state: $state)';
}


}

/// @nodoc
abstract mixin class _$PullChangeCopyWith<$Res> implements $PullChangeCopyWith<$Res> {
  factory _$PullChangeCopyWith(_PullChange value, $Res Function(_PullChange) _then) = __$PullChangeCopyWithImpl;
@override @useResult
$Res call({
 EntityKind entity, String entityId, int revision, bool isTombstone, Map<String, dynamic>? state
});




}
/// @nodoc
class __$PullChangeCopyWithImpl<$Res>
    implements _$PullChangeCopyWith<$Res> {
  __$PullChangeCopyWithImpl(this._self, this._then);

  final _PullChange _self;
  final $Res Function(_PullChange) _then;

/// Create a copy of PullChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entity = null,Object? entityId = null,Object? revision = null,Object? isTombstone = null,Object? state = freezed,}) {
  return _then(_PullChange(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as EntityKind,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,isTombstone: null == isTombstone ? _self.isTombstone : isTombstone // ignore: cast_nullable_to_non_nullable
as bool,state: freezed == state ? _self._state : state // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
