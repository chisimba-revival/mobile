// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sighting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WildlifeSighting {

 String get id; String get contextCode; String get driveId; SightingStatus get status;/// The contract carries this as a GeoJSON `Point`, so it is written as one
/// rather than as a flat longitude and latitude pair. The converter is
/// named explicitly because `GeoPoint` is hand-written rather than
/// generated, and json_serializable will not infer a codec for it.
@GeoPointConverter() GeoPoint get location; DateTime get capturedAt; DateTime get recordedAt; int get revision; String get createdBy; String? get speciesCode; int? get count; double? get locationAccuracyM; int? get distanceM; int? get bearingDeg; SightingBehaviour? get behaviour; AgeSexClass? get ageSexClass; String? get notes; String? get verifiedBy; DateTime? get verifiedAt; String? get verificationNotes; String? get recordedSpeciesCode; int? get recordedCount; bool get lateArrival;
/// Create a copy of WildlifeSighting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WildlifeSightingCopyWith<WildlifeSighting> get copyWith => _$WildlifeSightingCopyWithImpl<WildlifeSighting>(this as WildlifeSighting, _$identity);

  /// Serializes this WildlifeSighting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WildlifeSighting;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WildlifeSighting&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.contextCode, _this.contextCode) || other.contextCode == _this.contextCode)&&(identical(other.driveId, _this.driveId) || other.driveId == _this.driveId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.capturedAt, _this.capturedAt) || other.capturedAt == _this.capturedAt)&&(identical(other.recordedAt, _this.recordedAt) || other.recordedAt == _this.recordedAt)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.speciesCode, _this.speciesCode) || other.speciesCode == _this.speciesCode)&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.locationAccuracyM, _this.locationAccuracyM) || other.locationAccuracyM == _this.locationAccuracyM)&&(identical(other.distanceM, _this.distanceM) || other.distanceM == _this.distanceM)&&(identical(other.bearingDeg, _this.bearingDeg) || other.bearingDeg == _this.bearingDeg)&&(identical(other.behaviour, _this.behaviour) || other.behaviour == _this.behaviour)&&(identical(other.ageSexClass, _this.ageSexClass) || other.ageSexClass == _this.ageSexClass)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.verifiedBy, _this.verifiedBy) || other.verifiedBy == _this.verifiedBy)&&(identical(other.verifiedAt, _this.verifiedAt) || other.verifiedAt == _this.verifiedAt)&&(identical(other.verificationNotes, _this.verificationNotes) || other.verificationNotes == _this.verificationNotes)&&(identical(other.recordedSpeciesCode, _this.recordedSpeciesCode) || other.recordedSpeciesCode == _this.recordedSpeciesCode)&&(identical(other.recordedCount, _this.recordedCount) || other.recordedCount == _this.recordedCount)&&(identical(other.lateArrival, _this.lateArrival) || other.lateArrival == _this.lateArrival));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WildlifeSighting;
  return Object.hashAll([runtimeType,_this.id,_this.contextCode,_this.driveId,_this.status,_this.location,_this.capturedAt,_this.recordedAt,_this.revision,_this.createdBy,_this.speciesCode,_this.count,_this.locationAccuracyM,_this.distanceM,_this.bearingDeg,_this.behaviour,_this.ageSexClass,_this.notes,_this.verifiedBy,_this.verifiedAt,_this.verificationNotes,_this.recordedSpeciesCode,_this.recordedCount,_this.lateArrival]);
}

@override
String toString() {
  final _this = this as WildlifeSighting;
  return 'WildlifeSighting(id: ${_this.id}, contextCode: ${_this.contextCode}, driveId: ${_this.driveId}, status: ${_this.status}, location: ${_this.location}, capturedAt: ${_this.capturedAt}, recordedAt: ${_this.recordedAt}, revision: ${_this.revision}, createdBy: ${_this.createdBy}, speciesCode: ${_this.speciesCode}, count: ${_this.count}, locationAccuracyM: ${_this.locationAccuracyM}, distanceM: ${_this.distanceM}, bearingDeg: ${_this.bearingDeg}, behaviour: ${_this.behaviour}, ageSexClass: ${_this.ageSexClass}, notes: ${_this.notes}, verifiedBy: ${_this.verifiedBy}, verifiedAt: ${_this.verifiedAt}, verificationNotes: ${_this.verificationNotes}, recordedSpeciesCode: ${_this.recordedSpeciesCode}, recordedCount: ${_this.recordedCount}, lateArrival: ${_this.lateArrival})';
}


}

/// @nodoc
abstract mixin class $WildlifeSightingCopyWith<$Res>  {
  factory $WildlifeSightingCopyWith(WildlifeSighting value, $Res Function(WildlifeSighting) _then) = _$WildlifeSightingCopyWithImpl;
@useResult
$Res call({
 String id, String contextCode, String driveId, SightingStatus status,@GeoPointConverter() GeoPoint location, DateTime capturedAt, DateTime recordedAt, int revision, String createdBy, String? speciesCode, int? count, double? locationAccuracyM, int? distanceM, int? bearingDeg, SightingBehaviour? behaviour, AgeSexClass? ageSexClass, String? notes, String? verifiedBy, DateTime? verifiedAt, String? verificationNotes, String? recordedSpeciesCode, int? recordedCount, bool lateArrival
});




}
/// @nodoc
class _$WildlifeSightingCopyWithImpl<$Res>
    implements $WildlifeSightingCopyWith<$Res> {
  _$WildlifeSightingCopyWithImpl(this._self, this._then);

  final WildlifeSighting _self;
  final $Res Function(WildlifeSighting) _then;

/// Create a copy of WildlifeSighting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contextCode = null,Object? driveId = null,Object? status = null,Object? location = null,Object? capturedAt = null,Object? recordedAt = null,Object? revision = null,Object? createdBy = null,Object? speciesCode = freezed,Object? count = freezed,Object? locationAccuracyM = freezed,Object? distanceM = freezed,Object? bearingDeg = freezed,Object? behaviour = freezed,Object? ageSexClass = freezed,Object? notes = freezed,Object? verifiedBy = freezed,Object? verifiedAt = freezed,Object? verificationNotes = freezed,Object? recordedSpeciesCode = freezed,Object? recordedCount = freezed,Object? lateArrival = null,}) {
  return _then(WildlifeSighting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contextCode: null == contextCode ? _self.contextCode : contextCode // ignore: cast_nullable_to_non_nullable
as String,driveId: null == driveId ? _self.driveId : driveId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SightingStatus,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,speciesCode: freezed == speciesCode ? _self.speciesCode : speciesCode // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,locationAccuracyM: freezed == locationAccuracyM ? _self.locationAccuracyM : locationAccuracyM // ignore: cast_nullable_to_non_nullable
as double?,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int?,bearingDeg: freezed == bearingDeg ? _self.bearingDeg : bearingDeg // ignore: cast_nullable_to_non_nullable
as int?,behaviour: freezed == behaviour ? _self.behaviour : behaviour // ignore: cast_nullable_to_non_nullable
as SightingBehaviour?,ageSexClass: freezed == ageSexClass ? _self.ageSexClass : ageSexClass // ignore: cast_nullable_to_non_nullable
as AgeSexClass?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,verifiedBy: freezed == verifiedBy ? _self.verifiedBy : verifiedBy // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,verificationNotes: freezed == verificationNotes ? _self.verificationNotes : verificationNotes // ignore: cast_nullable_to_non_nullable
as String?,recordedSpeciesCode: freezed == recordedSpeciesCode ? _self.recordedSpeciesCode : recordedSpeciesCode // ignore: cast_nullable_to_non_nullable
as String?,recordedCount: freezed == recordedCount ? _self.recordedCount : recordedCount // ignore: cast_nullable_to_non_nullable
as int?,lateArrival: null == lateArrival ? _self.lateArrival : lateArrival // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WildlifeSighting].
extension WildlifeSightingPatterns on WildlifeSighting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WildlifeSighting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WildlifeSighting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WildlifeSighting value)  $default,){
final _that = this;
switch (_that) {
case _WildlifeSighting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WildlifeSighting value)?  $default,){
final _that = this;
switch (_that) {
case _WildlifeSighting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String contextCode,  String driveId,  SightingStatus status, @GeoPointConverter()  GeoPoint location,  DateTime capturedAt,  DateTime recordedAt,  int revision,  String createdBy,  String? speciesCode,  int? count,  double? locationAccuracyM,  int? distanceM,  int? bearingDeg,  SightingBehaviour? behaviour,  AgeSexClass? ageSexClass,  String? notes,  String? verifiedBy,  DateTime? verifiedAt,  String? verificationNotes,  String? recordedSpeciesCode,  int? recordedCount,  bool lateArrival)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WildlifeSighting() when $default != null:
return $default(_that.id,_that.contextCode,_that.driveId,_that.status,_that.location,_that.capturedAt,_that.recordedAt,_that.revision,_that.createdBy,_that.speciesCode,_that.count,_that.locationAccuracyM,_that.distanceM,_that.bearingDeg,_that.behaviour,_that.ageSexClass,_that.notes,_that.verifiedBy,_that.verifiedAt,_that.verificationNotes,_that.recordedSpeciesCode,_that.recordedCount,_that.lateArrival);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String contextCode,  String driveId,  SightingStatus status, @GeoPointConverter()  GeoPoint location,  DateTime capturedAt,  DateTime recordedAt,  int revision,  String createdBy,  String? speciesCode,  int? count,  double? locationAccuracyM,  int? distanceM,  int? bearingDeg,  SightingBehaviour? behaviour,  AgeSexClass? ageSexClass,  String? notes,  String? verifiedBy,  DateTime? verifiedAt,  String? verificationNotes,  String? recordedSpeciesCode,  int? recordedCount,  bool lateArrival)  $default,) {final _that = this;
switch (_that) {
case _WildlifeSighting():
return $default(_that.id,_that.contextCode,_that.driveId,_that.status,_that.location,_that.capturedAt,_that.recordedAt,_that.revision,_that.createdBy,_that.speciesCode,_that.count,_that.locationAccuracyM,_that.distanceM,_that.bearingDeg,_that.behaviour,_that.ageSexClass,_that.notes,_that.verifiedBy,_that.verifiedAt,_that.verificationNotes,_that.recordedSpeciesCode,_that.recordedCount,_that.lateArrival);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String contextCode,  String driveId,  SightingStatus status, @GeoPointConverter()  GeoPoint location,  DateTime capturedAt,  DateTime recordedAt,  int revision,  String createdBy,  String? speciesCode,  int? count,  double? locationAccuracyM,  int? distanceM,  int? bearingDeg,  SightingBehaviour? behaviour,  AgeSexClass? ageSexClass,  String? notes,  String? verifiedBy,  DateTime? verifiedAt,  String? verificationNotes,  String? recordedSpeciesCode,  int? recordedCount,  bool lateArrival)?  $default,) {final _that = this;
switch (_that) {
case _WildlifeSighting() when $default != null:
return $default(_that.id,_that.contextCode,_that.driveId,_that.status,_that.location,_that.capturedAt,_that.recordedAt,_that.revision,_that.createdBy,_that.speciesCode,_that.count,_that.locationAccuracyM,_that.distanceM,_that.bearingDeg,_that.behaviour,_that.ageSexClass,_that.notes,_that.verifiedBy,_that.verifiedAt,_that.verificationNotes,_that.recordedSpeciesCode,_that.recordedCount,_that.lateArrival);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WildlifeSighting extends WildlifeSighting {
  const _WildlifeSighting({required this.id, required this.contextCode, required this.driveId, required this.status, @GeoPointConverter() required this.location, required this.capturedAt, required this.recordedAt, required this.revision, required this.createdBy, this.speciesCode, this.count, this.locationAccuracyM, this.distanceM, this.bearingDeg, this.behaviour, this.ageSexClass, this.notes, this.verifiedBy, this.verifiedAt, this.verificationNotes, this.recordedSpeciesCode, this.recordedCount, this.lateArrival = false}): super._();
  factory _WildlifeSighting.fromJson(Map<String, dynamic> json) => _$WildlifeSightingFromJson(json);

@override final  String id;
@override final  String contextCode;
@override final  String driveId;
@override final  SightingStatus status;
/// The contract carries this as a GeoJSON `Point`, so it is written as one
/// rather than as a flat longitude and latitude pair. The converter is
/// named explicitly because `GeoPoint` is hand-written rather than
/// generated, and json_serializable will not infer a codec for it.
@override@GeoPointConverter() final  GeoPoint location;
@override final  DateTime capturedAt;
@override final  DateTime recordedAt;
@override final  int revision;
@override final  String createdBy;
@override final  String? speciesCode;
@override final  int? count;
@override final  double? locationAccuracyM;
@override final  int? distanceM;
@override final  int? bearingDeg;
@override final  SightingBehaviour? behaviour;
@override final  AgeSexClass? ageSexClass;
@override final  String? notes;
@override final  String? verifiedBy;
@override final  DateTime? verifiedAt;
@override final  String? verificationNotes;
@override final  String? recordedSpeciesCode;
@override final  int? recordedCount;
@override@JsonKey() final  bool lateArrival;

/// Create a copy of WildlifeSighting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WildlifeSightingCopyWith<_WildlifeSighting> get copyWith => __$WildlifeSightingCopyWithImpl<_WildlifeSighting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WildlifeSightingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WildlifeSighting&&(identical(other.id, id) || other.id == id)&&(identical(other.contextCode, contextCode) || other.contextCode == contextCode)&&(identical(other.driveId, driveId) || other.driveId == driveId)&&(identical(other.status, status) || other.status == status)&&(identical(other.location, location) || other.location == location)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.speciesCode, speciesCode) || other.speciesCode == speciesCode)&&(identical(other.count, count) || other.count == count)&&(identical(other.locationAccuracyM, locationAccuracyM) || other.locationAccuracyM == locationAccuracyM)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.bearingDeg, bearingDeg) || other.bearingDeg == bearingDeg)&&(identical(other.behaviour, behaviour) || other.behaviour == behaviour)&&(identical(other.ageSexClass, ageSexClass) || other.ageSexClass == ageSexClass)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.verifiedBy, verifiedBy) || other.verifiedBy == verifiedBy)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.verificationNotes, verificationNotes) || other.verificationNotes == verificationNotes)&&(identical(other.recordedSpeciesCode, recordedSpeciesCode) || other.recordedSpeciesCode == recordedSpeciesCode)&&(identical(other.recordedCount, recordedCount) || other.recordedCount == recordedCount)&&(identical(other.lateArrival, lateArrival) || other.lateArrival == lateArrival));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,contextCode,driveId,status,location,capturedAt,recordedAt,revision,createdBy,speciesCode,count,locationAccuracyM,distanceM,bearingDeg,behaviour,ageSexClass,notes,verifiedBy,verifiedAt,verificationNotes,recordedSpeciesCode,recordedCount,lateArrival]);
}

@override
String toString() {
    return 'WildlifeSighting(id: $id, contextCode: $contextCode, driveId: $driveId, status: $status, location: $location, capturedAt: $capturedAt, recordedAt: $recordedAt, revision: $revision, createdBy: $createdBy, speciesCode: $speciesCode, count: $count, locationAccuracyM: $locationAccuracyM, distanceM: $distanceM, bearingDeg: $bearingDeg, behaviour: $behaviour, ageSexClass: $ageSexClass, notes: $notes, verifiedBy: $verifiedBy, verifiedAt: $verifiedAt, verificationNotes: $verificationNotes, recordedSpeciesCode: $recordedSpeciesCode, recordedCount: $recordedCount, lateArrival: $lateArrival)';
}


}

/// @nodoc
abstract mixin class _$WildlifeSightingCopyWith<$Res> implements $WildlifeSightingCopyWith<$Res> {
  factory _$WildlifeSightingCopyWith(_WildlifeSighting value, $Res Function(_WildlifeSighting) _then) = __$WildlifeSightingCopyWithImpl;
@override @useResult
$Res call({
 String id, String contextCode, String driveId, SightingStatus status,@GeoPointConverter() GeoPoint location, DateTime capturedAt, DateTime recordedAt, int revision, String createdBy, String? speciesCode, int? count, double? locationAccuracyM, int? distanceM, int? bearingDeg, SightingBehaviour? behaviour, AgeSexClass? ageSexClass, String? notes, String? verifiedBy, DateTime? verifiedAt, String? verificationNotes, String? recordedSpeciesCode, int? recordedCount, bool lateArrival
});




}
/// @nodoc
class __$WildlifeSightingCopyWithImpl<$Res>
    implements _$WildlifeSightingCopyWith<$Res> {
  __$WildlifeSightingCopyWithImpl(this._self, this._then);

  final _WildlifeSighting _self;
  final $Res Function(_WildlifeSighting) _then;

/// Create a copy of WildlifeSighting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contextCode = null,Object? driveId = null,Object? status = null,Object? location = null,Object? capturedAt = null,Object? recordedAt = null,Object? revision = null,Object? createdBy = null,Object? speciesCode = freezed,Object? count = freezed,Object? locationAccuracyM = freezed,Object? distanceM = freezed,Object? bearingDeg = freezed,Object? behaviour = freezed,Object? ageSexClass = freezed,Object? notes = freezed,Object? verifiedBy = freezed,Object? verifiedAt = freezed,Object? verificationNotes = freezed,Object? recordedSpeciesCode = freezed,Object? recordedCount = freezed,Object? lateArrival = null,}) {
  return _then(_WildlifeSighting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contextCode: null == contextCode ? _self.contextCode : contextCode // ignore: cast_nullable_to_non_nullable
as String,driveId: null == driveId ? _self.driveId : driveId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SightingStatus,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,speciesCode: freezed == speciesCode ? _self.speciesCode : speciesCode // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,locationAccuracyM: freezed == locationAccuracyM ? _self.locationAccuracyM : locationAccuracyM // ignore: cast_nullable_to_non_nullable
as double?,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int?,bearingDeg: freezed == bearingDeg ? _self.bearingDeg : bearingDeg // ignore: cast_nullable_to_non_nullable
as int?,behaviour: freezed == behaviour ? _self.behaviour : behaviour // ignore: cast_nullable_to_non_nullable
as SightingBehaviour?,ageSexClass: freezed == ageSexClass ? _self.ageSexClass : ageSexClass // ignore: cast_nullable_to_non_nullable
as AgeSexClass?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,verifiedBy: freezed == verifiedBy ? _self.verifiedBy : verifiedBy // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,verificationNotes: freezed == verificationNotes ? _self.verificationNotes : verificationNotes // ignore: cast_nullable_to_non_nullable
as String?,recordedSpeciesCode: freezed == recordedSpeciesCode ? _self.recordedSpeciesCode : recordedSpeciesCode // ignore: cast_nullable_to_non_nullable
as String?,recordedCount: freezed == recordedCount ? _self.recordedCount : recordedCount // ignore: cast_nullable_to_non_nullable
as int?,lateArrival: null == lateArrival ? _self.lateArrival : lateArrival // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
