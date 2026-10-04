// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SightingsTable extends Sightings
    with TableInfo<$SightingsTable, SightingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SightingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextCodeMeta = const VerificationMeta(
    'contextCode',
  );
  @override
  late final GeneratedColumn<String> contextCode = GeneratedColumn<String>(
    'context_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driveIdMeta = const VerificationMeta(
    'driveId',
  );
  @override
  late final GeneratedColumn<String> driveId = GeneratedColumn<String>(
    'drive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speciesCodeMeta = const VerificationMeta(
    'speciesCode',
  );
  @override
  late final GeneratedColumn<String> speciesCode = GeneratedColumn<String>(
    'species_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLatMeta = const VerificationMeta(
    'locationLat',
  );
  @override
  late final GeneratedColumn<double> locationLat = GeneratedColumn<double>(
    'location_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationLngMeta = const VerificationMeta(
    'locationLng',
  );
  @override
  late final GeneratedColumn<double> locationLng = GeneratedColumn<double>(
    'location_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationAccuracyMMeta = const VerificationMeta(
    'locationAccuracyM',
  );
  @override
  late final GeneratedColumn<double> locationAccuracyM =
      GeneratedColumn<double>(
        'location_accuracy_m',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bearingDegMeta = const VerificationMeta(
    'bearingDeg',
  );
  @override
  late final GeneratedColumn<int> bearingDeg = GeneratedColumn<int>(
    'bearing_deg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _behaviourMeta = const VerificationMeta(
    'behaviour',
  );
  @override
  late final GeneratedColumn<String> behaviour = GeneratedColumn<String>(
    'behaviour',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageSexClassMeta = const VerificationMeta(
    'ageSexClass',
  );
  @override
  late final GeneratedColumn<String> ageSexClass = GeneratedColumn<String>(
    'age_sex_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SightingStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SightingStatus>($SightingsTable.$converterstatus);
  static const VerificationMeta _verifiedByMeta = const VerificationMeta(
    'verifiedBy',
  );
  @override
  late final GeneratedColumn<String> verifiedBy = GeneratedColumn<String>(
    'verified_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verificationNotesMeta = const VerificationMeta(
    'verificationNotes',
  );
  @override
  late final GeneratedColumn<String> verificationNotes =
      GeneratedColumn<String>(
        'verification_notes',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recordedSpeciesCodeMeta =
      const VerificationMeta('recordedSpeciesCode');
  @override
  late final GeneratedColumn<String> recordedSpeciesCode =
      GeneratedColumn<String>(
        'recorded_species_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recordedCountMeta = const VerificationMeta(
    'recordedCount',
  );
  @override
  late final GeneratedColumn<int> recordedCount = GeneratedColumn<int>(
    'recorded_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctionReasonMeta = const VerificationMeta(
    'correctionReason',
  );
  @override
  late final GeneratedColumn<String> correctionReason = GeneratedColumn<String>(
    'correction_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lateArrivalMeta = const VerificationMeta(
    'lateArrival',
  );
  @override
  late final GeneratedColumn<bool> lateArrival = GeneratedColumn<bool>(
    'late_arrival',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("late_arrival" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTombstoneMeta = const VerificationMeta(
    'isTombstone',
  );
  @override
  late final GeneratedColumn<bool> isTombstone = GeneratedColumn<bool>(
    'is_tombstone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tombstone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasPendingChangesMeta = const VerificationMeta(
    'hasPendingChanges',
  );
  @override
  late final GeneratedColumn<bool> hasPendingChanges = GeneratedColumn<bool>(
    'has_pending_changes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_pending_changes" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    contextCode,
    driveId,
    speciesCode,
    count,
    locationLat,
    locationLng,
    locationAccuracyM,
    distanceM,
    bearingDeg,
    behaviour,
    ageSexClass,
    notes,
    status,
    verifiedBy,
    verifiedAt,
    verificationNotes,
    recordedSpeciesCode,
    recordedCount,
    correctionReason,
    lateArrival,
    capturedAt,
    recordedAt,
    revision,
    createdBy,
    isTombstone,
    deletedAt,
    hasPendingChanges,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sightings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SightingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('context_code')) {
      context.handle(
        _contextCodeMeta,
        contextCode.isAcceptableOrUnknown(
          data['context_code']!,
          _contextCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextCodeMeta);
    }
    if (data.containsKey('drive_id')) {
      context.handle(
        _driveIdMeta,
        driveId.isAcceptableOrUnknown(data['drive_id']!, _driveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_driveIdMeta);
    }
    if (data.containsKey('species_code')) {
      context.handle(
        _speciesCodeMeta,
        speciesCode.isAcceptableOrUnknown(
          data['species_code']!,
          _speciesCodeMeta,
        ),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('location_lat')) {
      context.handle(
        _locationLatMeta,
        locationLat.isAcceptableOrUnknown(
          data['location_lat']!,
          _locationLatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationLatMeta);
    }
    if (data.containsKey('location_lng')) {
      context.handle(
        _locationLngMeta,
        locationLng.isAcceptableOrUnknown(
          data['location_lng']!,
          _locationLngMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationLngMeta);
    }
    if (data.containsKey('location_accuracy_m')) {
      context.handle(
        _locationAccuracyMMeta,
        locationAccuracyM.isAcceptableOrUnknown(
          data['location_accuracy_m']!,
          _locationAccuracyMMeta,
        ),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('bearing_deg')) {
      context.handle(
        _bearingDegMeta,
        bearingDeg.isAcceptableOrUnknown(data['bearing_deg']!, _bearingDegMeta),
      );
    }
    if (data.containsKey('behaviour')) {
      context.handle(
        _behaviourMeta,
        behaviour.isAcceptableOrUnknown(data['behaviour']!, _behaviourMeta),
      );
    }
    if (data.containsKey('age_sex_class')) {
      context.handle(
        _ageSexClassMeta,
        ageSexClass.isAcceptableOrUnknown(
          data['age_sex_class']!,
          _ageSexClassMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('verified_by')) {
      context.handle(
        _verifiedByMeta,
        verifiedBy.isAcceptableOrUnknown(data['verified_by']!, _verifiedByMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('verification_notes')) {
      context.handle(
        _verificationNotesMeta,
        verificationNotes.isAcceptableOrUnknown(
          data['verification_notes']!,
          _verificationNotesMeta,
        ),
      );
    }
    if (data.containsKey('recorded_species_code')) {
      context.handle(
        _recordedSpeciesCodeMeta,
        recordedSpeciesCode.isAcceptableOrUnknown(
          data['recorded_species_code']!,
          _recordedSpeciesCodeMeta,
        ),
      );
    }
    if (data.containsKey('recorded_count')) {
      context.handle(
        _recordedCountMeta,
        recordedCount.isAcceptableOrUnknown(
          data['recorded_count']!,
          _recordedCountMeta,
        ),
      );
    }
    if (data.containsKey('correction_reason')) {
      context.handle(
        _correctionReasonMeta,
        correctionReason.isAcceptableOrUnknown(
          data['correction_reason']!,
          _correctionReasonMeta,
        ),
      );
    }
    if (data.containsKey('late_arrival')) {
      context.handle(
        _lateArrivalMeta,
        lateArrival.isAcceptableOrUnknown(
          data['late_arrival']!,
          _lateArrivalMeta,
        ),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('is_tombstone')) {
      context.handle(
        _isTombstoneMeta,
        isTombstone.isAcceptableOrUnknown(
          data['is_tombstone']!,
          _isTombstoneMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('has_pending_changes')) {
      context.handle(
        _hasPendingChangesMeta,
        hasPendingChanges.isAcceptableOrUnknown(
          data['has_pending_changes']!,
          _hasPendingChangesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SightingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SightingRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      contextCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_code'],
      )!,
      driveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_id'],
      )!,
      speciesCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species_code'],
      ),
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      ),
      locationLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lat'],
      )!,
      locationLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lng'],
      )!,
      locationAccuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_accuracy_m'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      ),
      bearingDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bearing_deg'],
      ),
      behaviour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}behaviour'],
      ),
      ageSexClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_sex_class'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: $SightingsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      verifiedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified_by'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      verificationNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_notes'],
      ),
      recordedSpeciesCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_species_code'],
      ),
      recordedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_count'],
      ),
      correctionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correction_reason'],
      ),
      lateArrival: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}late_arrival'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      isTombstone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tombstone'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hasPendingChanges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_pending_changes'],
      )!,
    );
  }

  @override
  $SightingsTable createAlias(String alias) {
    return $SightingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SightingStatus, String, String> $converterstatus =
      const EnumNameConverter<SightingStatus>(SightingStatus.values);
}

class SightingRow extends DataClass implements Insertable<SightingRow> {
  /// The id the *client* minted, from the very first save.
  ///
  /// This is the primary key rather than the server's id because a queued
  /// operation has to be able to name its subject before the service has ever
  /// heard of it. [serverId] stays null until the service assigns one.
  final String localId;

  /// The service's id for this record, once it has one.
  final String? serverId;

  /// Carried by every record. Access needs both scope and a context grant, so a
  /// sighting without one is not merely incomplete, it is unaddressable.
  final String contextCode;
  final String driveId;

  /// Null until verified. Rule 21: a trainee who saw something they could not
  /// name records a sighting with neither this nor [count], and forcing a guess
  /// at capture trains guessing.
  final String? speciesCode;

  /// Null until verified. An absent count is not a zero: a zero asserts the
  /// animal was looked for and there were none.
  final int? count;
  final double locationLat;
  final double locationLng;

  /// How sure the device was of its own position, in metres.
  ///
  /// Carried on the sighting rather than discarded after the fact so a reviewer
  /// can tell a precise fix from a coarse one.
  final double? locationAccuracyM;

  /// Distance and bearing exist so a reviewer can distinguish a genuinely new
  /// sighting from the same animals logged twice from a different seat, which is
  /// the most common error in a sighting log.
  final int? distanceM;
  final int? bearingDeg;

  /// Free text: the contract does not enumerate the allowed values.
  final String? behaviour;
  final String? ageSexClass;
  final String? notes;

  /// Enumerated by the contract, so it is constrained rather than free text.
  final SightingStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;

  /// The values before a correction, retained permanently.
  ///
  /// Rule 15 requires a reason for a correction *and* retention of the
  /// originals. Without these two columns a mentor cannot show a trainee what
  /// they originally said, which is the only way the correction teaches anything.
  final String? recordedSpeciesCode;
  final int? recordedCount;

  /// Why a correction happened, when there is one.
  ///
  /// Rule 15 makes the reason mandatory with the correction, so it is stored
  /// beside the retained originals rather than being inferred from them.
  final String? correctionReason;
  final bool lateArrival;

  /// When the observation happened. Rule 13: never interchangeable with
  /// [recordedAt], and neither arbitrates anything.
  final DateTime capturedAt;

  /// When this device recorded it. Diverges from [capturedAt] exactly when the
  /// device was offline, and conflating them makes an honest offline entry look
  /// late when it is not.
  final DateTime recordedAt;

  /// The service's revision, or 0 while the record has never been accepted.
  ///
  /// Rule 6: conflicts are decided by revision and never by timestamps, so this
  /// is the only field that participates in conflict resolution.
  final int revision;
  final String createdBy;

  /// Rule 9: deletion is a soft delete and a removal arrives as a record rather
  /// than as an absence. A client that treated it as an absence would re-send
  /// the deleted record on its next edit, because nothing local ever said it
  /// was gone.
  final bool isTombstone;
  final DateTime? deletedAt;

  /// Whether this row has local changes the service has not accepted.
  final bool hasPendingChanges;
  const SightingRow({
    required this.localId,
    this.serverId,
    required this.contextCode,
    required this.driveId,
    this.speciesCode,
    this.count,
    required this.locationLat,
    required this.locationLng,
    this.locationAccuracyM,
    this.distanceM,
    this.bearingDeg,
    this.behaviour,
    this.ageSexClass,
    this.notes,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.recordedSpeciesCode,
    this.recordedCount,
    this.correctionReason,
    required this.lateArrival,
    required this.capturedAt,
    required this.recordedAt,
    required this.revision,
    required this.createdBy,
    required this.isTombstone,
    this.deletedAt,
    required this.hasPendingChanges,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['context_code'] = Variable<String>(contextCode);
    map['drive_id'] = Variable<String>(driveId);
    if (!nullToAbsent || speciesCode != null) {
      map['species_code'] = Variable<String>(speciesCode);
    }
    if (!nullToAbsent || count != null) {
      map['count'] = Variable<int>(count);
    }
    map['location_lat'] = Variable<double>(locationLat);
    map['location_lng'] = Variable<double>(locationLng);
    if (!nullToAbsent || locationAccuracyM != null) {
      map['location_accuracy_m'] = Variable<double>(locationAccuracyM);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<int>(distanceM);
    }
    if (!nullToAbsent || bearingDeg != null) {
      map['bearing_deg'] = Variable<int>(bearingDeg);
    }
    if (!nullToAbsent || behaviour != null) {
      map['behaviour'] = Variable<String>(behaviour);
    }
    if (!nullToAbsent || ageSexClass != null) {
      map['age_sex_class'] = Variable<String>(ageSexClass);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['status'] = Variable<String>(
        $SightingsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || verifiedBy != null) {
      map['verified_by'] = Variable<String>(verifiedBy);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || verificationNotes != null) {
      map['verification_notes'] = Variable<String>(verificationNotes);
    }
    if (!nullToAbsent || recordedSpeciesCode != null) {
      map['recorded_species_code'] = Variable<String>(recordedSpeciesCode);
    }
    if (!nullToAbsent || recordedCount != null) {
      map['recorded_count'] = Variable<int>(recordedCount);
    }
    if (!nullToAbsent || correctionReason != null) {
      map['correction_reason'] = Variable<String>(correctionReason);
    }
    map['late_arrival'] = Variable<bool>(lateArrival);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['revision'] = Variable<int>(revision);
    map['created_by'] = Variable<String>(createdBy);
    map['is_tombstone'] = Variable<bool>(isTombstone);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['has_pending_changes'] = Variable<bool>(hasPendingChanges);
    return map;
  }

  SightingsCompanion toCompanion(bool nullToAbsent) {
    return SightingsCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      contextCode: Value(contextCode),
      driveId: Value(driveId),
      speciesCode: speciesCode == null && nullToAbsent
          ? const Value.absent()
          : Value(speciesCode),
      count: count == null && nullToAbsent
          ? const Value.absent()
          : Value(count),
      locationLat: Value(locationLat),
      locationLng: Value(locationLng),
      locationAccuracyM: locationAccuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(locationAccuracyM),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      bearingDeg: bearingDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(bearingDeg),
      behaviour: behaviour == null && nullToAbsent
          ? const Value.absent()
          : Value(behaviour),
      ageSexClass: ageSexClass == null && nullToAbsent
          ? const Value.absent()
          : Value(ageSexClass),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      verifiedBy: verifiedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedBy),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      verificationNotes: verificationNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(verificationNotes),
      recordedSpeciesCode: recordedSpeciesCode == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedSpeciesCode),
      recordedCount: recordedCount == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedCount),
      correctionReason: correctionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(correctionReason),
      lateArrival: Value(lateArrival),
      capturedAt: Value(capturedAt),
      recordedAt: Value(recordedAt),
      revision: Value(revision),
      createdBy: Value(createdBy),
      isTombstone: Value(isTombstone),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hasPendingChanges: Value(hasPendingChanges),
    );
  }

  factory SightingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SightingRow(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      contextCode: serializer.fromJson<String>(json['contextCode']),
      driveId: serializer.fromJson<String>(json['driveId']),
      speciesCode: serializer.fromJson<String?>(json['speciesCode']),
      count: serializer.fromJson<int?>(json['count']),
      locationLat: serializer.fromJson<double>(json['locationLat']),
      locationLng: serializer.fromJson<double>(json['locationLng']),
      locationAccuracyM: serializer.fromJson<double?>(
        json['locationAccuracyM'],
      ),
      distanceM: serializer.fromJson<int?>(json['distanceM']),
      bearingDeg: serializer.fromJson<int?>(json['bearingDeg']),
      behaviour: serializer.fromJson<String?>(json['behaviour']),
      ageSexClass: serializer.fromJson<String?>(json['ageSexClass']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: $SightingsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      verifiedBy: serializer.fromJson<String?>(json['verifiedBy']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      verificationNotes: serializer.fromJson<String?>(
        json['verificationNotes'],
      ),
      recordedSpeciesCode: serializer.fromJson<String?>(
        json['recordedSpeciesCode'],
      ),
      recordedCount: serializer.fromJson<int?>(json['recordedCount']),
      correctionReason: serializer.fromJson<String?>(json['correctionReason']),
      lateArrival: serializer.fromJson<bool>(json['lateArrival']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      isTombstone: serializer.fromJson<bool>(json['isTombstone']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hasPendingChanges: serializer.fromJson<bool>(json['hasPendingChanges']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'contextCode': serializer.toJson<String>(contextCode),
      'driveId': serializer.toJson<String>(driveId),
      'speciesCode': serializer.toJson<String?>(speciesCode),
      'count': serializer.toJson<int?>(count),
      'locationLat': serializer.toJson<double>(locationLat),
      'locationLng': serializer.toJson<double>(locationLng),
      'locationAccuracyM': serializer.toJson<double?>(locationAccuracyM),
      'distanceM': serializer.toJson<int?>(distanceM),
      'bearingDeg': serializer.toJson<int?>(bearingDeg),
      'behaviour': serializer.toJson<String?>(behaviour),
      'ageSexClass': serializer.toJson<String?>(ageSexClass),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(
        $SightingsTable.$converterstatus.toJson(status),
      ),
      'verifiedBy': serializer.toJson<String?>(verifiedBy),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'verificationNotes': serializer.toJson<String?>(verificationNotes),
      'recordedSpeciesCode': serializer.toJson<String?>(recordedSpeciesCode),
      'recordedCount': serializer.toJson<int?>(recordedCount),
      'correctionReason': serializer.toJson<String?>(correctionReason),
      'lateArrival': serializer.toJson<bool>(lateArrival),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'revision': serializer.toJson<int>(revision),
      'createdBy': serializer.toJson<String>(createdBy),
      'isTombstone': serializer.toJson<bool>(isTombstone),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hasPendingChanges': serializer.toJson<bool>(hasPendingChanges),
    };
  }

  SightingRow copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? contextCode,
    String? driveId,
    Value<String?> speciesCode = const Value.absent(),
    Value<int?> count = const Value.absent(),
    double? locationLat,
    double? locationLng,
    Value<double?> locationAccuracyM = const Value.absent(),
    Value<int?> distanceM = const Value.absent(),
    Value<int?> bearingDeg = const Value.absent(),
    Value<String?> behaviour = const Value.absent(),
    Value<String?> ageSexClass = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    SightingStatus? status,
    Value<String?> verifiedBy = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
    Value<String?> verificationNotes = const Value.absent(),
    Value<String?> recordedSpeciesCode = const Value.absent(),
    Value<int?> recordedCount = const Value.absent(),
    Value<String?> correctionReason = const Value.absent(),
    bool? lateArrival,
    DateTime? capturedAt,
    DateTime? recordedAt,
    int? revision,
    String? createdBy,
    bool? isTombstone,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? hasPendingChanges,
  }) => SightingRow(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    contextCode: contextCode ?? this.contextCode,
    driveId: driveId ?? this.driveId,
    speciesCode: speciesCode.present ? speciesCode.value : this.speciesCode,
    count: count.present ? count.value : this.count,
    locationLat: locationLat ?? this.locationLat,
    locationLng: locationLng ?? this.locationLng,
    locationAccuracyM: locationAccuracyM.present
        ? locationAccuracyM.value
        : this.locationAccuracyM,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    bearingDeg: bearingDeg.present ? bearingDeg.value : this.bearingDeg,
    behaviour: behaviour.present ? behaviour.value : this.behaviour,
    ageSexClass: ageSexClass.present ? ageSexClass.value : this.ageSexClass,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    verifiedBy: verifiedBy.present ? verifiedBy.value : this.verifiedBy,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    verificationNotes: verificationNotes.present
        ? verificationNotes.value
        : this.verificationNotes,
    recordedSpeciesCode: recordedSpeciesCode.present
        ? recordedSpeciesCode.value
        : this.recordedSpeciesCode,
    recordedCount: recordedCount.present
        ? recordedCount.value
        : this.recordedCount,
    correctionReason: correctionReason.present
        ? correctionReason.value
        : this.correctionReason,
    lateArrival: lateArrival ?? this.lateArrival,
    capturedAt: capturedAt ?? this.capturedAt,
    recordedAt: recordedAt ?? this.recordedAt,
    revision: revision ?? this.revision,
    createdBy: createdBy ?? this.createdBy,
    isTombstone: isTombstone ?? this.isTombstone,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
  );
  SightingRow copyWithCompanion(SightingsCompanion data) {
    return SightingRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      contextCode: data.contextCode.present
          ? data.contextCode.value
          : this.contextCode,
      driveId: data.driveId.present ? data.driveId.value : this.driveId,
      speciesCode: data.speciesCode.present
          ? data.speciesCode.value
          : this.speciesCode,
      count: data.count.present ? data.count.value : this.count,
      locationLat: data.locationLat.present
          ? data.locationLat.value
          : this.locationLat,
      locationLng: data.locationLng.present
          ? data.locationLng.value
          : this.locationLng,
      locationAccuracyM: data.locationAccuracyM.present
          ? data.locationAccuracyM.value
          : this.locationAccuracyM,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      bearingDeg: data.bearingDeg.present
          ? data.bearingDeg.value
          : this.bearingDeg,
      behaviour: data.behaviour.present ? data.behaviour.value : this.behaviour,
      ageSexClass: data.ageSexClass.present
          ? data.ageSexClass.value
          : this.ageSexClass,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      verifiedBy: data.verifiedBy.present
          ? data.verifiedBy.value
          : this.verifiedBy,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      verificationNotes: data.verificationNotes.present
          ? data.verificationNotes.value
          : this.verificationNotes,
      recordedSpeciesCode: data.recordedSpeciesCode.present
          ? data.recordedSpeciesCode.value
          : this.recordedSpeciesCode,
      recordedCount: data.recordedCount.present
          ? data.recordedCount.value
          : this.recordedCount,
      correctionReason: data.correctionReason.present
          ? data.correctionReason.value
          : this.correctionReason,
      lateArrival: data.lateArrival.present
          ? data.lateArrival.value
          : this.lateArrival,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      isTombstone: data.isTombstone.present
          ? data.isTombstone.value
          : this.isTombstone,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hasPendingChanges: data.hasPendingChanges.present
          ? data.hasPendingChanges.value
          : this.hasPendingChanges,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SightingRow(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('contextCode: $contextCode, ')
          ..write('driveId: $driveId, ')
          ..write('speciesCode: $speciesCode, ')
          ..write('count: $count, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLng: $locationLng, ')
          ..write('locationAccuracyM: $locationAccuracyM, ')
          ..write('distanceM: $distanceM, ')
          ..write('bearingDeg: $bearingDeg, ')
          ..write('behaviour: $behaviour, ')
          ..write('ageSexClass: $ageSexClass, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('verifiedBy: $verifiedBy, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('verificationNotes: $verificationNotes, ')
          ..write('recordedSpeciesCode: $recordedSpeciesCode, ')
          ..write('recordedCount: $recordedCount, ')
          ..write('correctionReason: $correctionReason, ')
          ..write('lateArrival: $lateArrival, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('revision: $revision, ')
          ..write('createdBy: $createdBy, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hasPendingChanges: $hasPendingChanges')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    localId,
    serverId,
    contextCode,
    driveId,
    speciesCode,
    count,
    locationLat,
    locationLng,
    locationAccuracyM,
    distanceM,
    bearingDeg,
    behaviour,
    ageSexClass,
    notes,
    status,
    verifiedBy,
    verifiedAt,
    verificationNotes,
    recordedSpeciesCode,
    recordedCount,
    correctionReason,
    lateArrival,
    capturedAt,
    recordedAt,
    revision,
    createdBy,
    isTombstone,
    deletedAt,
    hasPendingChanges,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SightingRow &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.contextCode == this.contextCode &&
          other.driveId == this.driveId &&
          other.speciesCode == this.speciesCode &&
          other.count == this.count &&
          other.locationLat == this.locationLat &&
          other.locationLng == this.locationLng &&
          other.locationAccuracyM == this.locationAccuracyM &&
          other.distanceM == this.distanceM &&
          other.bearingDeg == this.bearingDeg &&
          other.behaviour == this.behaviour &&
          other.ageSexClass == this.ageSexClass &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.verifiedBy == this.verifiedBy &&
          other.verifiedAt == this.verifiedAt &&
          other.verificationNotes == this.verificationNotes &&
          other.recordedSpeciesCode == this.recordedSpeciesCode &&
          other.recordedCount == this.recordedCount &&
          other.correctionReason == this.correctionReason &&
          other.lateArrival == this.lateArrival &&
          other.capturedAt == this.capturedAt &&
          other.recordedAt == this.recordedAt &&
          other.revision == this.revision &&
          other.createdBy == this.createdBy &&
          other.isTombstone == this.isTombstone &&
          other.deletedAt == this.deletedAt &&
          other.hasPendingChanges == this.hasPendingChanges);
}

class SightingsCompanion extends UpdateCompanion<SightingRow> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> contextCode;
  final Value<String> driveId;
  final Value<String?> speciesCode;
  final Value<int?> count;
  final Value<double> locationLat;
  final Value<double> locationLng;
  final Value<double?> locationAccuracyM;
  final Value<int?> distanceM;
  final Value<int?> bearingDeg;
  final Value<String?> behaviour;
  final Value<String?> ageSexClass;
  final Value<String?> notes;
  final Value<SightingStatus> status;
  final Value<String?> verifiedBy;
  final Value<DateTime?> verifiedAt;
  final Value<String?> verificationNotes;
  final Value<String?> recordedSpeciesCode;
  final Value<int?> recordedCount;
  final Value<String?> correctionReason;
  final Value<bool> lateArrival;
  final Value<DateTime> capturedAt;
  final Value<DateTime> recordedAt;
  final Value<int> revision;
  final Value<String> createdBy;
  final Value<bool> isTombstone;
  final Value<DateTime?> deletedAt;
  final Value<bool> hasPendingChanges;
  final Value<int> rowid;
  const SightingsCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.contextCode = const Value.absent(),
    this.driveId = const Value.absent(),
    this.speciesCode = const Value.absent(),
    this.count = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLng = const Value.absent(),
    this.locationAccuracyM = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.bearingDeg = const Value.absent(),
    this.behaviour = const Value.absent(),
    this.ageSexClass = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.verifiedBy = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.verificationNotes = const Value.absent(),
    this.recordedSpeciesCode = const Value.absent(),
    this.recordedCount = const Value.absent(),
    this.correctionReason = const Value.absent(),
    this.lateArrival = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hasPendingChanges = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SightingsCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String contextCode,
    required String driveId,
    this.speciesCode = const Value.absent(),
    this.count = const Value.absent(),
    required double locationLat,
    required double locationLng,
    this.locationAccuracyM = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.bearingDeg = const Value.absent(),
    this.behaviour = const Value.absent(),
    this.ageSexClass = const Value.absent(),
    this.notes = const Value.absent(),
    required SightingStatus status,
    this.verifiedBy = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.verificationNotes = const Value.absent(),
    this.recordedSpeciesCode = const Value.absent(),
    this.recordedCount = const Value.absent(),
    this.correctionReason = const Value.absent(),
    this.lateArrival = const Value.absent(),
    required DateTime capturedAt,
    required DateTime recordedAt,
    this.revision = const Value.absent(),
    required String createdBy,
    this.isTombstone = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hasPendingChanges = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       contextCode = Value(contextCode),
       driveId = Value(driveId),
       locationLat = Value(locationLat),
       locationLng = Value(locationLng),
       status = Value(status),
       capturedAt = Value(capturedAt),
       recordedAt = Value(recordedAt),
       createdBy = Value(createdBy);
  static Insertable<SightingRow> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? contextCode,
    Expression<String>? driveId,
    Expression<String>? speciesCode,
    Expression<int>? count,
    Expression<double>? locationLat,
    Expression<double>? locationLng,
    Expression<double>? locationAccuracyM,
    Expression<int>? distanceM,
    Expression<int>? bearingDeg,
    Expression<String>? behaviour,
    Expression<String>? ageSexClass,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? verifiedBy,
    Expression<DateTime>? verifiedAt,
    Expression<String>? verificationNotes,
    Expression<String>? recordedSpeciesCode,
    Expression<int>? recordedCount,
    Expression<String>? correctionReason,
    Expression<bool>? lateArrival,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? recordedAt,
    Expression<int>? revision,
    Expression<String>? createdBy,
    Expression<bool>? isTombstone,
    Expression<DateTime>? deletedAt,
    Expression<bool>? hasPendingChanges,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (contextCode != null) 'context_code': contextCode,
      if (driveId != null) 'drive_id': driveId,
      if (speciesCode != null) 'species_code': speciesCode,
      if (count != null) 'count': count,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (locationAccuracyM != null) 'location_accuracy_m': locationAccuracyM,
      if (distanceM != null) 'distance_m': distanceM,
      if (bearingDeg != null) 'bearing_deg': bearingDeg,
      if (behaviour != null) 'behaviour': behaviour,
      if (ageSexClass != null) 'age_sex_class': ageSexClass,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (verificationNotes != null) 'verification_notes': verificationNotes,
      if (recordedSpeciesCode != null)
        'recorded_species_code': recordedSpeciesCode,
      if (recordedCount != null) 'recorded_count': recordedCount,
      if (correctionReason != null) 'correction_reason': correctionReason,
      if (lateArrival != null) 'late_arrival': lateArrival,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (revision != null) 'revision': revision,
      if (createdBy != null) 'created_by': createdBy,
      if (isTombstone != null) 'is_tombstone': isTombstone,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hasPendingChanges != null) 'has_pending_changes': hasPendingChanges,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SightingsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? contextCode,
    Value<String>? driveId,
    Value<String?>? speciesCode,
    Value<int?>? count,
    Value<double>? locationLat,
    Value<double>? locationLng,
    Value<double?>? locationAccuracyM,
    Value<int?>? distanceM,
    Value<int?>? bearingDeg,
    Value<String?>? behaviour,
    Value<String?>? ageSexClass,
    Value<String?>? notes,
    Value<SightingStatus>? status,
    Value<String?>? verifiedBy,
    Value<DateTime?>? verifiedAt,
    Value<String?>? verificationNotes,
    Value<String?>? recordedSpeciesCode,
    Value<int?>? recordedCount,
    Value<String?>? correctionReason,
    Value<bool>? lateArrival,
    Value<DateTime>? capturedAt,
    Value<DateTime>? recordedAt,
    Value<int>? revision,
    Value<String>? createdBy,
    Value<bool>? isTombstone,
    Value<DateTime?>? deletedAt,
    Value<bool>? hasPendingChanges,
    Value<int>? rowid,
  }) {
    return SightingsCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      contextCode: contextCode ?? this.contextCode,
      driveId: driveId ?? this.driveId,
      speciesCode: speciesCode ?? this.speciesCode,
      count: count ?? this.count,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAccuracyM: locationAccuracyM ?? this.locationAccuracyM,
      distanceM: distanceM ?? this.distanceM,
      bearingDeg: bearingDeg ?? this.bearingDeg,
      behaviour: behaviour ?? this.behaviour,
      ageSexClass: ageSexClass ?? this.ageSexClass,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      recordedSpeciesCode: recordedSpeciesCode ?? this.recordedSpeciesCode,
      recordedCount: recordedCount ?? this.recordedCount,
      correctionReason: correctionReason ?? this.correctionReason,
      lateArrival: lateArrival ?? this.lateArrival,
      capturedAt: capturedAt ?? this.capturedAt,
      recordedAt: recordedAt ?? this.recordedAt,
      revision: revision ?? this.revision,
      createdBy: createdBy ?? this.createdBy,
      isTombstone: isTombstone ?? this.isTombstone,
      deletedAt: deletedAt ?? this.deletedAt,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (contextCode.present) {
      map['context_code'] = Variable<String>(contextCode.value);
    }
    if (driveId.present) {
      map['drive_id'] = Variable<String>(driveId.value);
    }
    if (speciesCode.present) {
      map['species_code'] = Variable<String>(speciesCode.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (locationLat.present) {
      map['location_lat'] = Variable<double>(locationLat.value);
    }
    if (locationLng.present) {
      map['location_lng'] = Variable<double>(locationLng.value);
    }
    if (locationAccuracyM.present) {
      map['location_accuracy_m'] = Variable<double>(locationAccuracyM.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (bearingDeg.present) {
      map['bearing_deg'] = Variable<int>(bearingDeg.value);
    }
    if (behaviour.present) {
      map['behaviour'] = Variable<String>(behaviour.value);
    }
    if (ageSexClass.present) {
      map['age_sex_class'] = Variable<String>(ageSexClass.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SightingsTable.$converterstatus.toSql(status.value),
      );
    }
    if (verifiedBy.present) {
      map['verified_by'] = Variable<String>(verifiedBy.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (verificationNotes.present) {
      map['verification_notes'] = Variable<String>(verificationNotes.value);
    }
    if (recordedSpeciesCode.present) {
      map['recorded_species_code'] = Variable<String>(
        recordedSpeciesCode.value,
      );
    }
    if (recordedCount.present) {
      map['recorded_count'] = Variable<int>(recordedCount.value);
    }
    if (correctionReason.present) {
      map['correction_reason'] = Variable<String>(correctionReason.value);
    }
    if (lateArrival.present) {
      map['late_arrival'] = Variable<bool>(lateArrival.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (isTombstone.present) {
      map['is_tombstone'] = Variable<bool>(isTombstone.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hasPendingChanges.present) {
      map['has_pending_changes'] = Variable<bool>(hasPendingChanges.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SightingsCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('contextCode: $contextCode, ')
          ..write('driveId: $driveId, ')
          ..write('speciesCode: $speciesCode, ')
          ..write('count: $count, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLng: $locationLng, ')
          ..write('locationAccuracyM: $locationAccuracyM, ')
          ..write('distanceM: $distanceM, ')
          ..write('bearingDeg: $bearingDeg, ')
          ..write('behaviour: $behaviour, ')
          ..write('ageSexClass: $ageSexClass, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('verifiedBy: $verifiedBy, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('verificationNotes: $verificationNotes, ')
          ..write('recordedSpeciesCode: $recordedSpeciesCode, ')
          ..write('recordedCount: $recordedCount, ')
          ..write('correctionReason: $correctionReason, ')
          ..write('lateArrival: $lateArrival, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('revision: $revision, ')
          ..write('createdBy: $createdBy, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hasPendingChanges: $hasPendingChanges, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DrivesTable extends Drives with TableInfo<$DrivesTable, DriveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextCodeMeta = const VerificationMeta(
    'contextCode',
  );
  @override
  late final GeneratedColumn<String> contextCode = GeneratedColumn<String>(
    'context_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sealedAtMeta = const VerificationMeta(
    'sealedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sealedAt = GeneratedColumn<DateTime>(
    'sealed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isTombstoneMeta = const VerificationMeta(
    'isTombstone',
  );
  @override
  late final GeneratedColumn<bool> isTombstone = GeneratedColumn<bool>(
    'is_tombstone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tombstone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasPendingChangesMeta = const VerificationMeta(
    'hasPendingChanges',
  );
  @override
  late final GeneratedColumn<bool> hasPendingChanges = GeneratedColumn<bool>(
    'has_pending_changes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_pending_changes" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    contextCode,
    startedAt,
    endedAt,
    sealedAt,
    revision,
    isTombstone,
    deletedAt,
    hasPendingChanges,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drives';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriveRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('context_code')) {
      context.handle(
        _contextCodeMeta,
        contextCode.isAcceptableOrUnknown(
          data['context_code']!,
          _contextCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextCodeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('sealed_at')) {
      context.handle(
        _sealedAtMeta,
        sealedAt.isAcceptableOrUnknown(data['sealed_at']!, _sealedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('is_tombstone')) {
      context.handle(
        _isTombstoneMeta,
        isTombstone.isAcceptableOrUnknown(
          data['is_tombstone']!,
          _isTombstoneMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('has_pending_changes')) {
      context.handle(
        _hasPendingChangesMeta,
        hasPendingChanges.isAcceptableOrUnknown(
          data['has_pending_changes']!,
          _hasPendingChangesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  DriveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriveRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      contextCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_code'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      sealedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sealed_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      isTombstone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tombstone'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hasPendingChanges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_pending_changes'],
      )!,
    );
  }

  @override
  $DrivesTable createAlias(String alias) {
    return $DrivesTable(attachedDatabase, alias);
  }
}

class DriveRow extends DataClass implements Insertable<DriveRow> {
  final String localId;
  final String? serverId;
  final String contextCode;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Set only by an explicit seal. A drive can be ended and still accept a
  /// sighting that was genuinely observed on it.
  final DateTime? sealedAt;
  final int revision;
  final bool isTombstone;
  final DateTime? deletedAt;
  final bool hasPendingChanges;
  const DriveRow({
    required this.localId,
    this.serverId,
    required this.contextCode,
    required this.startedAt,
    this.endedAt,
    this.sealedAt,
    required this.revision,
    required this.isTombstone,
    this.deletedAt,
    required this.hasPendingChanges,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['context_code'] = Variable<String>(contextCode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || sealedAt != null) {
      map['sealed_at'] = Variable<DateTime>(sealedAt);
    }
    map['revision'] = Variable<int>(revision);
    map['is_tombstone'] = Variable<bool>(isTombstone);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['has_pending_changes'] = Variable<bool>(hasPendingChanges);
    return map;
  }

  DrivesCompanion toCompanion(bool nullToAbsent) {
    return DrivesCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      contextCode: Value(contextCode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      sealedAt: sealedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sealedAt),
      revision: Value(revision),
      isTombstone: Value(isTombstone),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hasPendingChanges: Value(hasPendingChanges),
    );
  }

  factory DriveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriveRow(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      contextCode: serializer.fromJson<String>(json['contextCode']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      sealedAt: serializer.fromJson<DateTime?>(json['sealedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      isTombstone: serializer.fromJson<bool>(json['isTombstone']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hasPendingChanges: serializer.fromJson<bool>(json['hasPendingChanges']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'contextCode': serializer.toJson<String>(contextCode),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'sealedAt': serializer.toJson<DateTime?>(sealedAt),
      'revision': serializer.toJson<int>(revision),
      'isTombstone': serializer.toJson<bool>(isTombstone),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hasPendingChanges': serializer.toJson<bool>(hasPendingChanges),
    };
  }

  DriveRow copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? contextCode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<DateTime?> sealedAt = const Value.absent(),
    int? revision,
    bool? isTombstone,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? hasPendingChanges,
  }) => DriveRow(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    contextCode: contextCode ?? this.contextCode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    sealedAt: sealedAt.present ? sealedAt.value : this.sealedAt,
    revision: revision ?? this.revision,
    isTombstone: isTombstone ?? this.isTombstone,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
  );
  DriveRow copyWithCompanion(DrivesCompanion data) {
    return DriveRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      contextCode: data.contextCode.present
          ? data.contextCode.value
          : this.contextCode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      sealedAt: data.sealedAt.present ? data.sealedAt.value : this.sealedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      isTombstone: data.isTombstone.present
          ? data.isTombstone.value
          : this.isTombstone,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hasPendingChanges: data.hasPendingChanges.present
          ? data.hasPendingChanges.value
          : this.hasPendingChanges,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriveRow(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('contextCode: $contextCode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('sealedAt: $sealedAt, ')
          ..write('revision: $revision, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hasPendingChanges: $hasPendingChanges')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    contextCode,
    startedAt,
    endedAt,
    sealedAt,
    revision,
    isTombstone,
    deletedAt,
    hasPendingChanges,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriveRow &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.contextCode == this.contextCode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.sealedAt == this.sealedAt &&
          other.revision == this.revision &&
          other.isTombstone == this.isTombstone &&
          other.deletedAt == this.deletedAt &&
          other.hasPendingChanges == this.hasPendingChanges);
}

class DrivesCompanion extends UpdateCompanion<DriveRow> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> contextCode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime?> sealedAt;
  final Value<int> revision;
  final Value<bool> isTombstone;
  final Value<DateTime?> deletedAt;
  final Value<bool> hasPendingChanges;
  final Value<int> rowid;
  const DrivesCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.contextCode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.sealedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hasPendingChanges = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DrivesCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String contextCode,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.sealedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hasPendingChanges = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       contextCode = Value(contextCode),
       startedAt = Value(startedAt);
  static Insertable<DriveRow> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? contextCode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? sealedAt,
    Expression<int>? revision,
    Expression<bool>? isTombstone,
    Expression<DateTime>? deletedAt,
    Expression<bool>? hasPendingChanges,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (contextCode != null) 'context_code': contextCode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (sealedAt != null) 'sealed_at': sealedAt,
      if (revision != null) 'revision': revision,
      if (isTombstone != null) 'is_tombstone': isTombstone,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hasPendingChanges != null) 'has_pending_changes': hasPendingChanges,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DrivesCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? contextCode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime?>? sealedAt,
    Value<int>? revision,
    Value<bool>? isTombstone,
    Value<DateTime?>? deletedAt,
    Value<bool>? hasPendingChanges,
    Value<int>? rowid,
  }) {
    return DrivesCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      contextCode: contextCode ?? this.contextCode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      sealedAt: sealedAt ?? this.sealedAt,
      revision: revision ?? this.revision,
      isTombstone: isTombstone ?? this.isTombstone,
      deletedAt: deletedAt ?? this.deletedAt,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (contextCode.present) {
      map['context_code'] = Variable<String>(contextCode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (sealedAt.present) {
      map['sealed_at'] = Variable<DateTime>(sealedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (isTombstone.present) {
      map['is_tombstone'] = Variable<bool>(isTombstone.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hasPendingChanges.present) {
      map['has_pending_changes'] = Variable<bool>(hasPendingChanges.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrivesCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('contextCode: $contextCode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('sealedAt: $sealedAt, ')
          ..write('revision: $revision, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hasPendingChanges: $hasPendingChanges, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailLogsTable extends TrailLogs
    with TableInfo<$TrailLogsTable, TrailLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextCodeMeta = const VerificationMeta(
    'contextCode',
  );
  @override
  late final GeneratedColumn<String> contextCode = GeneratedColumn<String>(
    'context_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driveIdMeta = const VerificationMeta(
    'driveId',
  );
  @override
  late final GeneratedColumn<String> driveId = GeneratedColumn<String>(
    'drive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trailCodeMeta = const VerificationMeta(
    'trailCode',
  );
  @override
  late final GeneratedColumn<String> trailCode = GeneratedColumn<String>(
    'trail_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isTombstoneMeta = const VerificationMeta(
    'isTombstone',
  );
  @override
  late final GeneratedColumn<bool> isTombstone = GeneratedColumn<bool>(
    'is_tombstone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tombstone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    contextCode,
    driveId,
    trailCode,
    startedAt,
    endedAt,
    notes,
    revision,
    isTombstone,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('context_code')) {
      context.handle(
        _contextCodeMeta,
        contextCode.isAcceptableOrUnknown(
          data['context_code']!,
          _contextCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextCodeMeta);
    }
    if (data.containsKey('drive_id')) {
      context.handle(
        _driveIdMeta,
        driveId.isAcceptableOrUnknown(data['drive_id']!, _driveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_driveIdMeta);
    }
    if (data.containsKey('trail_code')) {
      context.handle(
        _trailCodeMeta,
        trailCode.isAcceptableOrUnknown(data['trail_code']!, _trailCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_trailCodeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('is_tombstone')) {
      context.handle(
        _isTombstoneMeta,
        isTombstone.isAcceptableOrUnknown(
          data['is_tombstone']!,
          _isTombstoneMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  TrailLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailLogRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      contextCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_code'],
      )!,
      driveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_id'],
      )!,
      trailCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_code'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      isTombstone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tombstone'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TrailLogsTable createAlias(String alias) {
    return $TrailLogsTable(attachedDatabase, alias);
  }
}

class TrailLogRow extends DataClass implements Insertable<TrailLogRow> {
  final String localId;
  final String? serverId;
  final String contextCode;
  final String driveId;
  final String trailCode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  final int revision;
  final bool isTombstone;
  final DateTime? deletedAt;
  const TrailLogRow({
    required this.localId,
    this.serverId,
    required this.contextCode,
    required this.driveId,
    required this.trailCode,
    required this.startedAt,
    this.endedAt,
    this.notes,
    required this.revision,
    required this.isTombstone,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['context_code'] = Variable<String>(contextCode);
    map['drive_id'] = Variable<String>(driveId);
    map['trail_code'] = Variable<String>(trailCode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['revision'] = Variable<int>(revision);
    map['is_tombstone'] = Variable<bool>(isTombstone);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TrailLogsCompanion toCompanion(bool nullToAbsent) {
    return TrailLogsCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      contextCode: Value(contextCode),
      driveId: Value(driveId),
      trailCode: Value(trailCode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      revision: Value(revision),
      isTombstone: Value(isTombstone),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TrailLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailLogRow(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      contextCode: serializer.fromJson<String>(json['contextCode']),
      driveId: serializer.fromJson<String>(json['driveId']),
      trailCode: serializer.fromJson<String>(json['trailCode']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      revision: serializer.fromJson<int>(json['revision']),
      isTombstone: serializer.fromJson<bool>(json['isTombstone']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'contextCode': serializer.toJson<String>(contextCode),
      'driveId': serializer.toJson<String>(driveId),
      'trailCode': serializer.toJson<String>(trailCode),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'notes': serializer.toJson<String?>(notes),
      'revision': serializer.toJson<int>(revision),
      'isTombstone': serializer.toJson<bool>(isTombstone),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TrailLogRow copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? contextCode,
    String? driveId,
    String? trailCode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? revision,
    bool? isTombstone,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TrailLogRow(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    contextCode: contextCode ?? this.contextCode,
    driveId: driveId ?? this.driveId,
    trailCode: trailCode ?? this.trailCode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    notes: notes.present ? notes.value : this.notes,
    revision: revision ?? this.revision,
    isTombstone: isTombstone ?? this.isTombstone,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TrailLogRow copyWithCompanion(TrailLogsCompanion data) {
    return TrailLogRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      contextCode: data.contextCode.present
          ? data.contextCode.value
          : this.contextCode,
      driveId: data.driveId.present ? data.driveId.value : this.driveId,
      trailCode: data.trailCode.present ? data.trailCode.value : this.trailCode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      revision: data.revision.present ? data.revision.value : this.revision,
      isTombstone: data.isTombstone.present
          ? data.isTombstone.value
          : this.isTombstone,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailLogRow(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('contextCode: $contextCode, ')
          ..write('driveId: $driveId, ')
          ..write('trailCode: $trailCode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes, ')
          ..write('revision: $revision, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    contextCode,
    driveId,
    trailCode,
    startedAt,
    endedAt,
    notes,
    revision,
    isTombstone,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailLogRow &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.contextCode == this.contextCode &&
          other.driveId == this.driveId &&
          other.trailCode == this.trailCode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.notes == this.notes &&
          other.revision == this.revision &&
          other.isTombstone == this.isTombstone &&
          other.deletedAt == this.deletedAt);
}

class TrailLogsCompanion extends UpdateCompanion<TrailLogRow> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> contextCode;
  final Value<String> driveId;
  final Value<String> trailCode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> notes;
  final Value<int> revision;
  final Value<bool> isTombstone;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TrailLogsCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.contextCode = const Value.absent(),
    this.driveId = const Value.absent(),
    this.trailCode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.revision = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailLogsCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String contextCode,
    required String driveId,
    required String trailCode,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.revision = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       contextCode = Value(contextCode),
       driveId = Value(driveId),
       trailCode = Value(trailCode),
       startedAt = Value(startedAt);
  static Insertable<TrailLogRow> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? contextCode,
    Expression<String>? driveId,
    Expression<String>? trailCode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? notes,
    Expression<int>? revision,
    Expression<bool>? isTombstone,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (contextCode != null) 'context_code': contextCode,
      if (driveId != null) 'drive_id': driveId,
      if (trailCode != null) 'trail_code': trailCode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (notes != null) 'notes': notes,
      if (revision != null) 'revision': revision,
      if (isTombstone != null) 'is_tombstone': isTombstone,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailLogsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? contextCode,
    Value<String>? driveId,
    Value<String>? trailCode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? notes,
    Value<int>? revision,
    Value<bool>? isTombstone,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TrailLogsCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      contextCode: contextCode ?? this.contextCode,
      driveId: driveId ?? this.driveId,
      trailCode: trailCode ?? this.trailCode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      revision: revision ?? this.revision,
      isTombstone: isTombstone ?? this.isTombstone,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (contextCode.present) {
      map['context_code'] = Variable<String>(contextCode.value);
    }
    if (driveId.present) {
      map['drive_id'] = Variable<String>(driveId.value);
    }
    if (trailCode.present) {
      map['trail_code'] = Variable<String>(trailCode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (isTombstone.present) {
      map['is_tombstone'] = Variable<bool>(isTombstone.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('contextCode: $contextCode, ')
          ..write('driveId: $driveId, ')
          ..write('trailCode: $trailCode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes, ')
          ..write('revision: $revision, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueuedOperationsTable extends QueuedOperations
    with TableInfo<$QueuedOperationsTable, QueuedOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntityKind, String> entity =
      GeneratedColumn<String>(
        'entity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntityKind>($QueuedOperationsTable.$converterentity);
  @override
  late final GeneratedColumnWithTypeConverter<OperationKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OperationKind>($QueuedOperationsTable.$converterkind);
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OperationState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<OperationState>($QueuedOperationsTable.$converterstate);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enqueuedAtMeta = const VerificationMeta(
    'enqueuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> enqueuedAt = GeneratedColumn<DateTime>(
    'enqueued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PushOutcome?, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PushOutcome?>($QueuedOperationsTable.$converteroutcomen);
  static const VerificationMeta _serverRevisionMeta = const VerificationMeta(
    'serverRevision',
  );
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
    'server_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    entityId,
    entity,
    kind,
    baseRevision,
    capturedAt,
    recordedAt,
    dependsOn,
    payload,
    state,
    attempts,
    enqueuedAt,
    settledAt,
    outcome,
    serverRevision,
    errorCode,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseRevisionMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('enqueued_at')) {
      context.handle(
        _enqueuedAtMeta,
        enqueuedAt.isAcceptableOrUnknown(data['enqueued_at']!, _enqueuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enqueuedAtMeta);
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    }
    if (data.containsKey('server_revision')) {
      context.handle(
        _serverRevisionMeta,
        serverRevision.isAcceptableOrUnknown(
          data['server_revision']!,
          _serverRevisionMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  QueuedOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedOperationRow(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entity: $QueuedOperationsTable.$converterentity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}entity'],
        )!,
      ),
      kind: $QueuedOperationsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      state: $QueuedOperationsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      enqueuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enqueued_at'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      ),
      outcome: $QueuedOperationsTable.$converteroutcomen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        ),
      ),
      serverRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_revision'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $QueuedOperationsTable createAlias(String alias) {
    return $QueuedOperationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntityKind, String, String> $converterentity =
      const EnumNameConverter<EntityKind>(EntityKind.values);
  static JsonTypeConverter2<OperationKind, String, String> $converterkind =
      const EnumNameConverter<OperationKind>(OperationKind.values);
  static JsonTypeConverter2<OperationState, String, String> $converterstate =
      const EnumNameConverter<OperationState>(OperationState.values);
  static JsonTypeConverter2<PushOutcome, String, String> $converteroutcome =
      const EnumNameConverter<PushOutcome>(PushOutcome.values);
  static JsonTypeConverter2<PushOutcome?, String?, String?> $converteroutcomen =
      JsonTypeConverter2.asNullable($converteroutcome);
}

class QueuedOperationRow extends DataClass
    implements Insertable<QueuedOperationRow> {
  /// The retry identity, and the idempotency key the service will see.
  final String operationId;

  /// The device-minted id of the record this operation concerns.
  final String entityId;
  final EntityKind entity;

  /// An intent, never a whole-entity replacement.
  final OperationKind kind;

  /// The revision this edit was made against. Rule 6: the only input to
  /// conflict resolution.
  final int baseRevision;
  final DateTime capturedAt;
  final DateTime recordedAt;

  /// A declared prerequisite that must settle first, named by its own
  /// operation id.
  final String? dependsOn;

  /// The operation payload as JSON.
  ///
  /// Kept as the exact bytes that will be sent, because a `deferred` outcome
  /// re-queues the same payload rather than rebuilding it. Rebuilding would
  /// risk quietly changing what the guide actually asked for.
  final String payload;
  final OperationState state;

  /// How many times this has been offered. Diagnostic only: nothing in the
  /// contract makes a retry count significant.
  final int attempts;
  final DateTime enqueuedAt;
  final DateTime? settledAt;

  /// The terminal answer, if there is one.
  final PushOutcome? outcome;
  final int? serverRevision;

  /// The stable error code from a refusal.
  final String? errorCode;
  final String? errorMessage;
  const QueuedOperationRow({
    required this.operationId,
    required this.entityId,
    required this.entity,
    required this.kind,
    required this.baseRevision,
    required this.capturedAt,
    required this.recordedAt,
    this.dependsOn,
    required this.payload,
    required this.state,
    required this.attempts,
    required this.enqueuedAt,
    this.settledAt,
    this.outcome,
    this.serverRevision,
    this.errorCode,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['entity_id'] = Variable<String>(entityId);
    {
      map['entity'] = Variable<String>(
        $QueuedOperationsTable.$converterentity.toSql(entity),
      );
    }
    {
      map['kind'] = Variable<String>(
        $QueuedOperationsTable.$converterkind.toSql(kind),
      );
    }
    map['base_revision'] = Variable<int>(baseRevision);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || dependsOn != null) {
      map['depends_on'] = Variable<String>(dependsOn);
    }
    map['payload'] = Variable<String>(payload);
    {
      map['state'] = Variable<String>(
        $QueuedOperationsTable.$converterstate.toSql(state),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    map['enqueued_at'] = Variable<DateTime>(enqueuedAt);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(
        $QueuedOperationsTable.$converteroutcomen.toSql(outcome),
      );
    }
    if (!nullToAbsent || serverRevision != null) {
      map['server_revision'] = Variable<int>(serverRevision);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  QueuedOperationsCompanion toCompanion(bool nullToAbsent) {
    return QueuedOperationsCompanion(
      operationId: Value(operationId),
      entityId: Value(entityId),
      entity: Value(entity),
      kind: Value(kind),
      baseRevision: Value(baseRevision),
      capturedAt: Value(capturedAt),
      recordedAt: Value(recordedAt),
      dependsOn: dependsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOn),
      payload: Value(payload),
      state: Value(state),
      attempts: Value(attempts),
      enqueuedAt: Value(enqueuedAt),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      serverRevision: serverRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRevision),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory QueuedOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedOperationRow(
      operationId: serializer.fromJson<String>(json['operationId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entity: $QueuedOperationsTable.$converterentity.fromJson(
        serializer.fromJson<String>(json['entity']),
      ),
      kind: $QueuedOperationsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      baseRevision: serializer.fromJson<int>(json['baseRevision']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      dependsOn: serializer.fromJson<String?>(json['dependsOn']),
      payload: serializer.fromJson<String>(json['payload']),
      state: $QueuedOperationsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      enqueuedAt: serializer.fromJson<DateTime>(json['enqueuedAt']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
      outcome: $QueuedOperationsTable.$converteroutcomen.fromJson(
        serializer.fromJson<String?>(json['outcome']),
      ),
      serverRevision: serializer.fromJson<int?>(json['serverRevision']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'entityId': serializer.toJson<String>(entityId),
      'entity': serializer.toJson<String>(
        $QueuedOperationsTable.$converterentity.toJson(entity),
      ),
      'kind': serializer.toJson<String>(
        $QueuedOperationsTable.$converterkind.toJson(kind),
      ),
      'baseRevision': serializer.toJson<int>(baseRevision),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'dependsOn': serializer.toJson<String?>(dependsOn),
      'payload': serializer.toJson<String>(payload),
      'state': serializer.toJson<String>(
        $QueuedOperationsTable.$converterstate.toJson(state),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'enqueuedAt': serializer.toJson<DateTime>(enqueuedAt),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
      'outcome': serializer.toJson<String?>(
        $QueuedOperationsTable.$converteroutcomen.toJson(outcome),
      ),
      'serverRevision': serializer.toJson<int?>(serverRevision),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  QueuedOperationRow copyWith({
    String? operationId,
    String? entityId,
    EntityKind? entity,
    OperationKind? kind,
    int? baseRevision,
    DateTime? capturedAt,
    DateTime? recordedAt,
    Value<String?> dependsOn = const Value.absent(),
    String? payload,
    OperationState? state,
    int? attempts,
    DateTime? enqueuedAt,
    Value<DateTime?> settledAt = const Value.absent(),
    Value<PushOutcome?> outcome = const Value.absent(),
    Value<int?> serverRevision = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => QueuedOperationRow(
    operationId: operationId ?? this.operationId,
    entityId: entityId ?? this.entityId,
    entity: entity ?? this.entity,
    kind: kind ?? this.kind,
    baseRevision: baseRevision ?? this.baseRevision,
    capturedAt: capturedAt ?? this.capturedAt,
    recordedAt: recordedAt ?? this.recordedAt,
    dependsOn: dependsOn.present ? dependsOn.value : this.dependsOn,
    payload: payload ?? this.payload,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    enqueuedAt: enqueuedAt ?? this.enqueuedAt,
    settledAt: settledAt.present ? settledAt.value : this.settledAt,
    outcome: outcome.present ? outcome.value : this.outcome,
    serverRevision: serverRevision.present
        ? serverRevision.value
        : this.serverRevision,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  QueuedOperationRow copyWithCompanion(QueuedOperationsCompanion data) {
    return QueuedOperationRow(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entity: data.entity.present ? data.entity.value : this.entity,
      kind: data.kind.present ? data.kind.value : this.kind,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      payload: data.payload.present ? data.payload.value : this.payload,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      enqueuedAt: data.enqueuedAt.present
          ? data.enqueuedAt.value
          : this.enqueuedAt,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedOperationRow(')
          ..write('operationId: $operationId, ')
          ..write('entityId: $entityId, ')
          ..write('entity: $entity, ')
          ..write('kind: $kind, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('payload: $payload, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('enqueuedAt: $enqueuedAt, ')
          ..write('settledAt: $settledAt, ')
          ..write('outcome: $outcome, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityId,
    entity,
    kind,
    baseRevision,
    capturedAt,
    recordedAt,
    dependsOn,
    payload,
    state,
    attempts,
    enqueuedAt,
    settledAt,
    outcome,
    serverRevision,
    errorCode,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedOperationRow &&
          other.operationId == this.operationId &&
          other.entityId == this.entityId &&
          other.entity == this.entity &&
          other.kind == this.kind &&
          other.baseRevision == this.baseRevision &&
          other.capturedAt == this.capturedAt &&
          other.recordedAt == this.recordedAt &&
          other.dependsOn == this.dependsOn &&
          other.payload == this.payload &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.enqueuedAt == this.enqueuedAt &&
          other.settledAt == this.settledAt &&
          other.outcome == this.outcome &&
          other.serverRevision == this.serverRevision &&
          other.errorCode == this.errorCode &&
          other.errorMessage == this.errorMessage);
}

class QueuedOperationsCompanion extends UpdateCompanion<QueuedOperationRow> {
  final Value<String> operationId;
  final Value<String> entityId;
  final Value<EntityKind> entity;
  final Value<OperationKind> kind;
  final Value<int> baseRevision;
  final Value<DateTime> capturedAt;
  final Value<DateTime> recordedAt;
  final Value<String?> dependsOn;
  final Value<String> payload;
  final Value<OperationState> state;
  final Value<int> attempts;
  final Value<DateTime> enqueuedAt;
  final Value<DateTime?> settledAt;
  final Value<PushOutcome?> outcome;
  final Value<int?> serverRevision;
  final Value<String?> errorCode;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const QueuedOperationsCompanion({
    this.operationId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entity = const Value.absent(),
    this.kind = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.payload = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.enqueuedAt = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueuedOperationsCompanion.insert({
    required String operationId,
    required String entityId,
    required EntityKind entity,
    required OperationKind kind,
    required int baseRevision,
    required DateTime capturedAt,
    required DateTime recordedAt,
    this.dependsOn = const Value.absent(),
    required String payload,
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime enqueuedAt,
    this.settledAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityId = Value(entityId),
       entity = Value(entity),
       kind = Value(kind),
       baseRevision = Value(baseRevision),
       capturedAt = Value(capturedAt),
       recordedAt = Value(recordedAt),
       payload = Value(payload),
       enqueuedAt = Value(enqueuedAt);
  static Insertable<QueuedOperationRow> custom({
    Expression<String>? operationId,
    Expression<String>? entityId,
    Expression<String>? entity,
    Expression<String>? kind,
    Expression<int>? baseRevision,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? recordedAt,
    Expression<String>? dependsOn,
    Expression<String>? payload,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<DateTime>? enqueuedAt,
    Expression<DateTime>? settledAt,
    Expression<String>? outcome,
    Expression<int>? serverRevision,
    Expression<String>? errorCode,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (entityId != null) 'entity_id': entityId,
      if (entity != null) 'entity': entity,
      if (kind != null) 'kind': kind,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (payload != null) 'payload': payload,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (enqueuedAt != null) 'enqueued_at': enqueuedAt,
      if (settledAt != null) 'settled_at': settledAt,
      if (outcome != null) 'outcome': outcome,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueuedOperationsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? entityId,
    Value<EntityKind>? entity,
    Value<OperationKind>? kind,
    Value<int>? baseRevision,
    Value<DateTime>? capturedAt,
    Value<DateTime>? recordedAt,
    Value<String?>? dependsOn,
    Value<String>? payload,
    Value<OperationState>? state,
    Value<int>? attempts,
    Value<DateTime>? enqueuedAt,
    Value<DateTime?>? settledAt,
    Value<PushOutcome?>? outcome,
    Value<int?>? serverRevision,
    Value<String?>? errorCode,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return QueuedOperationsCompanion(
      operationId: operationId ?? this.operationId,
      entityId: entityId ?? this.entityId,
      entity: entity ?? this.entity,
      kind: kind ?? this.kind,
      baseRevision: baseRevision ?? this.baseRevision,
      capturedAt: capturedAt ?? this.capturedAt,
      recordedAt: recordedAt ?? this.recordedAt,
      dependsOn: dependsOn ?? this.dependsOn,
      payload: payload ?? this.payload,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      enqueuedAt: enqueuedAt ?? this.enqueuedAt,
      settledAt: settledAt ?? this.settledAt,
      outcome: outcome ?? this.outcome,
      serverRevision: serverRevision ?? this.serverRevision,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(
        $QueuedOperationsTable.$converterentity.toSql(entity.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $QueuedOperationsTable.$converterkind.toSql(kind.value),
      );
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $QueuedOperationsTable.$converterstate.toSql(state.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (enqueuedAt.present) {
      map['enqueued_at'] = Variable<DateTime>(enqueuedAt.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $QueuedOperationsTable.$converteroutcomen.toSql(outcome.value),
      );
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedOperationsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('entityId: $entityId, ')
          ..write('entity: $entity, ')
          ..write('kind: $kind, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('payload: $payload, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('enqueuedAt: $enqueuedAt, ')
          ..write('settledAt: $settledAt, ')
          ..write('outcome: $outcome, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictsTable extends Conflicts
    with TableInfo<$ConflictsTable, ConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntityKind, String> entity =
      GeneratedColumn<String>(
        'entity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntityKind>($ConflictsTable.$converterentity);
  static const VerificationMeta _clientPayloadMeta = const VerificationMeta(
    'clientPayload',
  );
  @override
  late final GeneratedColumn<String> clientPayload = GeneratedColumn<String>(
    'client_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverStateMeta = const VerificationMeta(
    'serverState',
  );
  @override
  late final GeneratedColumn<String> serverState = GeneratedColumn<String>(
    'server_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverRevisionMeta = const VerificationMeta(
    'serverRevision',
  );
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
    'server_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    entityId,
    entity,
    clientPayload,
    serverState,
    serverRevision,
    baseRevision,
    errorCode,
    reason,
    recordedAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('client_payload')) {
      context.handle(
        _clientPayloadMeta,
        clientPayload.isAcceptableOrUnknown(
          data['client_payload']!,
          _clientPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPayloadMeta);
    }
    if (data.containsKey('server_state')) {
      context.handle(
        _serverStateMeta,
        serverState.isAcceptableOrUnknown(
          data['server_state']!,
          _serverStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverStateMeta);
    }
    if (data.containsKey('server_revision')) {
      context.handle(
        _serverRevisionMeta,
        serverRevision.isAcceptableOrUnknown(
          data['server_revision']!,
          _serverRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverRevisionMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseRevisionMeta);
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_errorCodeMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  ConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictRow(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entity: $ConflictsTable.$converterentity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}entity'],
        )!,
      ),
      clientPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_payload'],
      )!,
      serverState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_state'],
      )!,
      serverRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_revision'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $ConflictsTable createAlias(String alias) {
    return $ConflictsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntityKind, String, String> $converterentity =
      const EnumNameConverter<EntityKind>(EntityKind.values);
}

class ConflictRow extends DataClass implements Insertable<ConflictRow> {
  final String operationId;
  final String entityId;
  final EntityKind entity;

  /// What the offline edit said.
  final String clientPayload;

  /// What the service holds instead, as returned with the refusal.
  final String serverState;
  final int serverRevision;

  /// The revision the edit was made against, so the gap is legible.
  final int baseRevision;
  final String errorCode;

  /// Why the guide gave for the edit, when the change was a correction.
  final String? reason;
  final DateTime recordedAt;
  final DateTime? resolvedAt;
  const ConflictRow({
    required this.operationId,
    required this.entityId,
    required this.entity,
    required this.clientPayload,
    required this.serverState,
    required this.serverRevision,
    required this.baseRevision,
    required this.errorCode,
    this.reason,
    required this.recordedAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['entity_id'] = Variable<String>(entityId);
    {
      map['entity'] = Variable<String>(
        $ConflictsTable.$converterentity.toSql(entity),
      );
    }
    map['client_payload'] = Variable<String>(clientPayload);
    map['server_state'] = Variable<String>(serverState);
    map['server_revision'] = Variable<int>(serverRevision);
    map['base_revision'] = Variable<int>(baseRevision);
    map['error_code'] = Variable<String>(errorCode);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  ConflictsCompanion toCompanion(bool nullToAbsent) {
    return ConflictsCompanion(
      operationId: Value(operationId),
      entityId: Value(entityId),
      entity: Value(entity),
      clientPayload: Value(clientPayload),
      serverState: Value(serverState),
      serverRevision: Value(serverRevision),
      baseRevision: Value(baseRevision),
      errorCode: Value(errorCode),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      recordedAt: Value(recordedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory ConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictRow(
      operationId: serializer.fromJson<String>(json['operationId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entity: $ConflictsTable.$converterentity.fromJson(
        serializer.fromJson<String>(json['entity']),
      ),
      clientPayload: serializer.fromJson<String>(json['clientPayload']),
      serverState: serializer.fromJson<String>(json['serverState']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
      baseRevision: serializer.fromJson<int>(json['baseRevision']),
      errorCode: serializer.fromJson<String>(json['errorCode']),
      reason: serializer.fromJson<String?>(json['reason']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'entityId': serializer.toJson<String>(entityId),
      'entity': serializer.toJson<String>(
        $ConflictsTable.$converterentity.toJson(entity),
      ),
      'clientPayload': serializer.toJson<String>(clientPayload),
      'serverState': serializer.toJson<String>(serverState),
      'serverRevision': serializer.toJson<int>(serverRevision),
      'baseRevision': serializer.toJson<int>(baseRevision),
      'errorCode': serializer.toJson<String>(errorCode),
      'reason': serializer.toJson<String?>(reason),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  ConflictRow copyWith({
    String? operationId,
    String? entityId,
    EntityKind? entity,
    String? clientPayload,
    String? serverState,
    int? serverRevision,
    int? baseRevision,
    String? errorCode,
    Value<String?> reason = const Value.absent(),
    DateTime? recordedAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => ConflictRow(
    operationId: operationId ?? this.operationId,
    entityId: entityId ?? this.entityId,
    entity: entity ?? this.entity,
    clientPayload: clientPayload ?? this.clientPayload,
    serverState: serverState ?? this.serverState,
    serverRevision: serverRevision ?? this.serverRevision,
    baseRevision: baseRevision ?? this.baseRevision,
    errorCode: errorCode ?? this.errorCode,
    reason: reason.present ? reason.value : this.reason,
    recordedAt: recordedAt ?? this.recordedAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  ConflictRow copyWithCompanion(ConflictsCompanion data) {
    return ConflictRow(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entity: data.entity.present ? data.entity.value : this.entity,
      clientPayload: data.clientPayload.present
          ? data.clientPayload.value
          : this.clientPayload,
      serverState: data.serverState.present
          ? data.serverState.value
          : this.serverState,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      reason: data.reason.present ? data.reason.value : this.reason,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRow(')
          ..write('operationId: $operationId, ')
          ..write('entityId: $entityId, ')
          ..write('entity: $entity, ')
          ..write('clientPayload: $clientPayload, ')
          ..write('serverState: $serverState, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('errorCode: $errorCode, ')
          ..write('reason: $reason, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityId,
    entity,
    clientPayload,
    serverState,
    serverRevision,
    baseRevision,
    errorCode,
    reason,
    recordedAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictRow &&
          other.operationId == this.operationId &&
          other.entityId == this.entityId &&
          other.entity == this.entity &&
          other.clientPayload == this.clientPayload &&
          other.serverState == this.serverState &&
          other.serverRevision == this.serverRevision &&
          other.baseRevision == this.baseRevision &&
          other.errorCode == this.errorCode &&
          other.reason == this.reason &&
          other.recordedAt == this.recordedAt &&
          other.resolvedAt == this.resolvedAt);
}

class ConflictsCompanion extends UpdateCompanion<ConflictRow> {
  final Value<String> operationId;
  final Value<String> entityId;
  final Value<EntityKind> entity;
  final Value<String> clientPayload;
  final Value<String> serverState;
  final Value<int> serverRevision;
  final Value<int> baseRevision;
  final Value<String> errorCode;
  final Value<String?> reason;
  final Value<DateTime> recordedAt;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const ConflictsCompanion({
    this.operationId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entity = const Value.absent(),
    this.clientPayload = const Value.absent(),
    this.serverState = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.reason = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictsCompanion.insert({
    required String operationId,
    required String entityId,
    required EntityKind entity,
    required String clientPayload,
    required String serverState,
    required int serverRevision,
    required int baseRevision,
    required String errorCode,
    this.reason = const Value.absent(),
    required DateTime recordedAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityId = Value(entityId),
       entity = Value(entity),
       clientPayload = Value(clientPayload),
       serverState = Value(serverState),
       serverRevision = Value(serverRevision),
       baseRevision = Value(baseRevision),
       errorCode = Value(errorCode),
       recordedAt = Value(recordedAt);
  static Insertable<ConflictRow> custom({
    Expression<String>? operationId,
    Expression<String>? entityId,
    Expression<String>? entity,
    Expression<String>? clientPayload,
    Expression<String>? serverState,
    Expression<int>? serverRevision,
    Expression<int>? baseRevision,
    Expression<String>? errorCode,
    Expression<String>? reason,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (entityId != null) 'entity_id': entityId,
      if (entity != null) 'entity': entity,
      if (clientPayload != null) 'client_payload': clientPayload,
      if (serverState != null) 'server_state': serverState,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (errorCode != null) 'error_code': errorCode,
      if (reason != null) 'reason': reason,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? entityId,
    Value<EntityKind>? entity,
    Value<String>? clientPayload,
    Value<String>? serverState,
    Value<int>? serverRevision,
    Value<int>? baseRevision,
    Value<String>? errorCode,
    Value<String?>? reason,
    Value<DateTime>? recordedAt,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return ConflictsCompanion(
      operationId: operationId ?? this.operationId,
      entityId: entityId ?? this.entityId,
      entity: entity ?? this.entity,
      clientPayload: clientPayload ?? this.clientPayload,
      serverState: serverState ?? this.serverState,
      serverRevision: serverRevision ?? this.serverRevision,
      baseRevision: baseRevision ?? this.baseRevision,
      errorCode: errorCode ?? this.errorCode,
      reason: reason ?? this.reason,
      recordedAt: recordedAt ?? this.recordedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(
        $ConflictsTable.$converterentity.toSql(entity.value),
      );
    }
    if (clientPayload.present) {
      map['client_payload'] = Variable<String>(clientPayload.value);
    }
    if (serverState.present) {
      map['server_state'] = Variable<String>(serverState.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('entityId: $entityId, ')
          ..write('entity: $entity, ')
          ..write('clientPayload: $clientPayload, ')
          ..write('serverState: $serverState, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('errorCode: $errorCode, ')
          ..write('reason: $reason, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverTimeAtApplyMeta = const VerificationMeta(
    'serverTimeAtApply',
  );
  @override
  late final GeneratedColumn<DateTime> serverTimeAtApply =
      GeneratedColumn<DateTime>(
        'server_time_at_apply',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scope,
    cursor,
    serverTimeAtApply,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('server_time_at_apply')) {
      context.handle(
        _serverTimeAtApplyMeta,
        serverTimeAtApply.isAcceptableOrUnknown(
          data['server_time_at_apply']!,
          _serverTimeAtApplyMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      serverTimeAtApply: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_time_at_apply'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String scope;

  /// The opaque cursor for the next pull. Null before the first pull.
  final String? cursor;

  /// The server time of the page most recently applied.
  final DateTime? serverTimeAtApply;
  final DateTime? updatedAt;
  const SyncCursorRow({
    required this.scope,
    this.cursor,
    this.serverTimeAtApply,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || serverTimeAtApply != null) {
      map['server_time_at_apply'] = Variable<DateTime>(serverTimeAtApply);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      scope: Value(scope),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      serverTimeAtApply: serverTimeAtApply == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTimeAtApply),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      scope: serializer.fromJson<String>(json['scope']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      serverTimeAtApply: serializer.fromJson<DateTime?>(
        json['serverTimeAtApply'],
      ),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'cursor': serializer.toJson<String?>(cursor),
      'serverTimeAtApply': serializer.toJson<DateTime?>(serverTimeAtApply),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SyncCursorRow copyWith({
    String? scope,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> serverTimeAtApply = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => SyncCursorRow(
    scope: scope ?? this.scope,
    cursor: cursor.present ? cursor.value : this.cursor,
    serverTimeAtApply: serverTimeAtApply.present
        ? serverTimeAtApply.value
        : this.serverTimeAtApply,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      scope: data.scope.present ? data.scope.value : this.scope,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      serverTimeAtApply: data.serverTimeAtApply.present
          ? data.serverTimeAtApply.value
          : this.serverTimeAtApply,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('scope: $scope, ')
          ..write('cursor: $cursor, ')
          ..write('serverTimeAtApply: $serverTimeAtApply, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, cursor, serverTimeAtApply, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.scope == this.scope &&
          other.cursor == this.cursor &&
          other.serverTimeAtApply == this.serverTimeAtApply &&
          other.updatedAt == this.updatedAt);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> scope;
  final Value<String?> cursor;
  final Value<DateTime?> serverTimeAtApply;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.scope = const Value.absent(),
    this.cursor = const Value.absent(),
    this.serverTimeAtApply = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String scope,
    this.cursor = const Value.absent(),
    this.serverTimeAtApply = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scope = Value(scope);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? scope,
    Expression<String>? cursor,
    Expression<DateTime>? serverTimeAtApply,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (cursor != null) 'cursor': cursor,
      if (serverTimeAtApply != null) 'server_time_at_apply': serverTimeAtApply,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? scope,
    Value<String?>? cursor,
    Value<DateTime?>? serverTimeAtApply,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      scope: scope ?? this.scope,
      cursor: cursor ?? this.cursor,
      serverTimeAtApply: serverTimeAtApply ?? this.serverTimeAtApply,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (serverTimeAtApply.present) {
      map['server_time_at_apply'] = Variable<DateTime>(serverTimeAtApply.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('scope: $scope, ')
          ..write('cursor: $cursor, ')
          ..write('serverTimeAtApply: $serverTimeAtApply, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReferenceDataTable extends ReferenceData
    with TableInfo<$ReferenceDataTable, ReferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, code, label, payload, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, code};
  @override
  ReferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
    );
  }

  @override
  $ReferenceDataTable createAlias(String alias) {
    return $ReferenceDataTable(attachedDatabase, alias);
  }
}

class ReferenceRow extends DataClass implements Insertable<ReferenceRow> {
  final String kind;
  final String code;
  final String? label;
  final String? payload;
  final DateTime? fetchedAt;
  const ReferenceRow({
    required this.kind,
    required this.code,
    this.label,
    this.payload,
    this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    return map;
  }

  ReferenceDataCompanion toCompanion(bool nullToAbsent) {
    return ReferenceDataCompanion(
      kind: Value(kind),
      code: Value(code),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
    );
  }

  factory ReferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceRow(
      kind: serializer.fromJson<String>(json['kind']),
      code: serializer.fromJson<String>(json['code']),
      label: serializer.fromJson<String?>(json['label']),
      payload: serializer.fromJson<String?>(json['payload']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'code': serializer.toJson<String>(code),
      'label': serializer.toJson<String?>(label),
      'payload': serializer.toJson<String?>(payload),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
    };
  }

  ReferenceRow copyWith({
    String? kind,
    String? code,
    Value<String?> label = const Value.absent(),
    Value<String?> payload = const Value.absent(),
    Value<DateTime?> fetchedAt = const Value.absent(),
  }) => ReferenceRow(
    kind: kind ?? this.kind,
    code: code ?? this.code,
    label: label.present ? label.value : this.label,
    payload: payload.present ? payload.value : this.payload,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
  );
  ReferenceRow copyWithCompanion(ReferenceDataCompanion data) {
    return ReferenceRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      code: data.code.present ? data.code.value : this.code,
      label: data.label.present ? data.label.value : this.label,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceRow(')
          ..write('kind: $kind, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, code, label, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceRow &&
          other.kind == this.kind &&
          other.code == this.code &&
          other.label == this.label &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class ReferenceDataCompanion extends UpdateCompanion<ReferenceRow> {
  final Value<String> kind;
  final Value<String> code;
  final Value<String?> label;
  final Value<String?> payload;
  final Value<DateTime?> fetchedAt;
  final Value<int> rowid;
  const ReferenceDataCompanion({
    this.kind = const Value.absent(),
    this.code = const Value.absent(),
    this.label = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReferenceDataCompanion.insert({
    required String kind,
    required String code,
    this.label = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       code = Value(code);
  static Insertable<ReferenceRow> custom({
    Expression<String>? kind,
    Expression<String>? code,
    Expression<String>? label,
    Expression<String>? payload,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (code != null) 'code': code,
      if (label != null) 'label': label,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReferenceDataCompanion copyWith({
    Value<String>? kind,
    Value<String>? code,
    Value<String?>? label,
    Value<String?>? payload,
    Value<DateTime?>? fetchedAt,
    Value<int>? rowid,
  }) {
    return ReferenceDataCompanion(
      kind: kind ?? this.kind,
      code: code ?? this.code,
      label: label ?? this.label,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceDataCompanion(')
          ..write('kind: $kind, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FieldLogDatabase extends GeneratedDatabase {
  _$FieldLogDatabase(QueryExecutor e) : super(e);
  $FieldLogDatabaseManager get managers => $FieldLogDatabaseManager(this);
  late final $SightingsTable sightings = $SightingsTable(this);
  late final $DrivesTable drives = $DrivesTable(this);
  late final $TrailLogsTable trailLogs = $TrailLogsTable(this);
  late final $QueuedOperationsTable queuedOperations = $QueuedOperationsTable(
    this,
  );
  late final $ConflictsTable conflicts = $ConflictsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $ReferenceDataTable referenceData = $ReferenceDataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sightings,
    drives,
    trailLogs,
    queuedOperations,
    conflicts,
    syncCursors,
    referenceData,
  ];
}

typedef $$SightingsTableCreateCompanionBuilder = SightingsCompanion Function({
  required String localId,
  Value<String?> serverId,
  required String contextCode,
  required String driveId,
  Value<String?> speciesCode,
  Value<int?> count,
  required double locationLat,
  required double locationLng,
  Value<double?> locationAccuracyM,
  Value<int?> distanceM,
  Value<int?> bearingDeg,
  Value<String?> behaviour,
  Value<String?> ageSexClass,
  Value<String?> notes,
  required SightingStatus status,
  Value<String?> verifiedBy,
  Value<DateTime?> verifiedAt,
  Value<String?> verificationNotes,
  Value<String?> recordedSpeciesCode,
  Value<int?> recordedCount,
  Value<String?> correctionReason,
  Value<bool> lateArrival,
  required DateTime capturedAt,
  required DateTime recordedAt,
  Value<int> revision,
  required String createdBy,
  Value<bool> isTombstone,
  Value<DateTime?> deletedAt,
  Value<bool> hasPendingChanges,
  Value<int> rowid,
});
typedef $$SightingsTableUpdateCompanionBuilder = SightingsCompanion Function({
  Value<String> localId,
  Value<String?> serverId,
  Value<String> contextCode,
  Value<String> driveId,
  Value<String?> speciesCode,
  Value<int?> count,
  Value<double> locationLat,
  Value<double> locationLng,
  Value<double?> locationAccuracyM,
  Value<int?> distanceM,
  Value<int?> bearingDeg,
  Value<String?> behaviour,
  Value<String?> ageSexClass,
  Value<String?> notes,
  Value<SightingStatus> status,
  Value<String?> verifiedBy,
  Value<DateTime?> verifiedAt,
  Value<String?> verificationNotes,
  Value<String?> recordedSpeciesCode,
  Value<int?> recordedCount,
  Value<String?> correctionReason,
  Value<bool> lateArrival,
  Value<DateTime> capturedAt,
  Value<DateTime> recordedAt,
  Value<int> revision,
  Value<String> createdBy,
  Value<bool> isTombstone,
  Value<DateTime?> deletedAt,
  Value<bool> hasPendingChanges,
  Value<int> rowid,
});

class $$SightingsTableFilterComposer
    extends Composer<_$FieldLogDatabase, $SightingsTable> {
  $$SightingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveId => $composableBuilder(
    column: $table.driveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speciesCode => $composableBuilder(
    column: $table.speciesCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationAccuracyM => $composableBuilder(
    column: $table.locationAccuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bearingDeg => $composableBuilder(
    column: $table.bearingDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get behaviour => $composableBuilder(
    column: $table.behaviour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageSexClass => $composableBuilder(
    column: $table.ageSexClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SightingStatus, SightingStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get verifiedBy => $composableBuilder(
    column: $table.verifiedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationNotes => $composableBuilder(
    column: $table.verificationNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedSpeciesCode => $composableBuilder(
    column: $table.recordedSpeciesCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedCount => $composableBuilder(
    column: $table.recordedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctionReason => $composableBuilder(
    column: $table.correctionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lateArrival => $composableBuilder(
    column: $table.lateArrival,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SightingsTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $SightingsTable> {
  $$SightingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveId => $composableBuilder(
    column: $table.driveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speciesCode => $composableBuilder(
    column: $table.speciesCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationAccuracyM => $composableBuilder(
    column: $table.locationAccuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bearingDeg => $composableBuilder(
    column: $table.bearingDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get behaviour => $composableBuilder(
    column: $table.behaviour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageSexClass => $composableBuilder(
    column: $table.ageSexClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifiedBy => $composableBuilder(
    column: $table.verifiedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationNotes => $composableBuilder(
    column: $table.verificationNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedSpeciesCode => $composableBuilder(
    column: $table.recordedSpeciesCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedCount => $composableBuilder(
    column: $table.recordedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctionReason => $composableBuilder(
    column: $table.correctionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lateArrival => $composableBuilder(
    column: $table.lateArrival,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SightingsTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $SightingsTable> {
  $$SightingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get driveId =>
      $composableBuilder(column: $table.driveId, builder: (column) => column);

  GeneratedColumn<String> get speciesCode => $composableBuilder(
    column: $table.speciesCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationAccuracyM => $composableBuilder(
    column: $table.locationAccuracyM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get bearingDeg => $composableBuilder(
    column: $table.bearingDeg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get behaviour =>
      $composableBuilder(column: $table.behaviour, builder: (column) => column);

  GeneratedColumn<String> get ageSexClass => $composableBuilder(
    column: $table.ageSexClass,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SightingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get verifiedBy => $composableBuilder(
    column: $table.verifiedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verificationNotes => $composableBuilder(
    column: $table.verificationNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedSpeciesCode => $composableBuilder(
    column: $table.recordedSpeciesCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedCount => $composableBuilder(
    column: $table.recordedCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctionReason => $composableBuilder(
    column: $table.correctionReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lateArrival => $composableBuilder(
    column: $table.lateArrival,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => column,
  );
}

class $$SightingsTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $SightingsTable,
          SightingRow,
          $$SightingsTableFilterComposer,
          $$SightingsTableOrderingComposer,
          $$SightingsTableAnnotationComposer,
          $$SightingsTableCreateCompanionBuilder,
          $$SightingsTableUpdateCompanionBuilder,
          (
            SightingRow,
            BaseReferences<_$FieldLogDatabase, $SightingsTable, SightingRow>,
          ),
          SightingRow,
          PrefetchHooks Function()
        > {
  $$SightingsTableTableManager(_$FieldLogDatabase db, $SightingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SightingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SightingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SightingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> contextCode = const Value.absent(),
                Value<String> driveId = const Value.absent(),
                Value<String?> speciesCode = const Value.absent(),
                Value<int?> count = const Value.absent(),
                Value<double> locationLat = const Value.absent(),
                Value<double> locationLng = const Value.absent(),
                Value<double?> locationAccuracyM = const Value.absent(),
                Value<int?> distanceM = const Value.absent(),
                Value<int?> bearingDeg = const Value.absent(),
                Value<String?> behaviour = const Value.absent(),
                Value<String?> ageSexClass = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<SightingStatus> status = const Value.absent(),
                Value<String?> verifiedBy = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<String?> verificationNotes = const Value.absent(),
                Value<String?> recordedSpeciesCode = const Value.absent(),
                Value<int?> recordedCount = const Value.absent(),
                Value<String?> correctionReason = const Value.absent(),
                Value<bool> lateArrival = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> hasPendingChanges = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SightingsCompanion(
                localId: localId,
                serverId: serverId,
                contextCode: contextCode,
                driveId: driveId,
                speciesCode: speciesCode,
                count: count,
                locationLat: locationLat,
                locationLng: locationLng,
                locationAccuracyM: locationAccuracyM,
                distanceM: distanceM,
                bearingDeg: bearingDeg,
                behaviour: behaviour,
                ageSexClass: ageSexClass,
                notes: notes,
                status: status,
                verifiedBy: verifiedBy,
                verifiedAt: verifiedAt,
                verificationNotes: verificationNotes,
                recordedSpeciesCode: recordedSpeciesCode,
                recordedCount: recordedCount,
                correctionReason: correctionReason,
                lateArrival: lateArrival,
                capturedAt: capturedAt,
                recordedAt: recordedAt,
                revision: revision,
                createdBy: createdBy,
                isTombstone: isTombstone,
                deletedAt: deletedAt,
                hasPendingChanges: hasPendingChanges,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String contextCode,
                required String driveId,
                Value<String?> speciesCode = const Value.absent(),
                Value<int?> count = const Value.absent(),
                required double locationLat,
                required double locationLng,
                Value<double?> locationAccuracyM = const Value.absent(),
                Value<int?> distanceM = const Value.absent(),
                Value<int?> bearingDeg = const Value.absent(),
                Value<String?> behaviour = const Value.absent(),
                Value<String?> ageSexClass = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required SightingStatus status,
                Value<String?> verifiedBy = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<String?> verificationNotes = const Value.absent(),
                Value<String?> recordedSpeciesCode = const Value.absent(),
                Value<int?> recordedCount = const Value.absent(),
                Value<String?> correctionReason = const Value.absent(),
                Value<bool> lateArrival = const Value.absent(),
                required DateTime capturedAt,
                required DateTime recordedAt,
                Value<int> revision = const Value.absent(),
                required String createdBy,
                Value<bool> isTombstone = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> hasPendingChanges = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SightingsCompanion.insert(
                localId: localId,
                serverId: serverId,
                contextCode: contextCode,
                driveId: driveId,
                speciesCode: speciesCode,
                count: count,
                locationLat: locationLat,
                locationLng: locationLng,
                locationAccuracyM: locationAccuracyM,
                distanceM: distanceM,
                bearingDeg: bearingDeg,
                behaviour: behaviour,
                ageSexClass: ageSexClass,
                notes: notes,
                status: status,
                verifiedBy: verifiedBy,
                verifiedAt: verifiedAt,
                verificationNotes: verificationNotes,
                recordedSpeciesCode: recordedSpeciesCode,
                recordedCount: recordedCount,
                correctionReason: correctionReason,
                lateArrival: lateArrival,
                capturedAt: capturedAt,
                recordedAt: recordedAt,
                revision: revision,
                createdBy: createdBy,
                isTombstone: isTombstone,
                deletedAt: deletedAt,
                hasPendingChanges: hasPendingChanges,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SightingsTable, SightingRow>(table),
                  BaseReferences<
                    _$FieldLogDatabase,
                    $SightingsTable,
                    SightingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SightingsTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $SightingsTable,
      SightingRow,
      $$SightingsTableFilterComposer,
      $$SightingsTableOrderingComposer,
      $$SightingsTableAnnotationComposer,
      $$SightingsTableCreateCompanionBuilder,
      $$SightingsTableUpdateCompanionBuilder,
      (
        SightingRow,
        BaseReferences<_$FieldLogDatabase, $SightingsTable, SightingRow>,
      ),
      SightingRow,
      PrefetchHooks Function()
    >;
typedef $$DrivesTableCreateCompanionBuilder = DrivesCompanion Function({
  required String localId,
  Value<String?> serverId,
  required String contextCode,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime?> sealedAt,
  Value<int> revision,
  Value<bool> isTombstone,
  Value<DateTime?> deletedAt,
  Value<bool> hasPendingChanges,
  Value<int> rowid,
});
typedef $$DrivesTableUpdateCompanionBuilder = DrivesCompanion Function({
  Value<String> localId,
  Value<String?> serverId,
  Value<String> contextCode,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime?> sealedAt,
  Value<int> revision,
  Value<bool> isTombstone,
  Value<DateTime?> deletedAt,
  Value<bool> hasPendingChanges,
  Value<int> rowid,
});

class $$DrivesTableFilterComposer
    extends Composer<_$FieldLogDatabase, $DrivesTable> {
  $$DrivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sealedAt => $composableBuilder(
    column: $table.sealedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrivesTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $DrivesTable> {
  $$DrivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sealedAt => $composableBuilder(
    column: $table.sealedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrivesTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $DrivesTable> {
  $$DrivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sealedAt =>
      $composableBuilder(column: $table.sealedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => column,
  );
}

class $$DrivesTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $DrivesTable,
          DriveRow,
          $$DrivesTableFilterComposer,
          $$DrivesTableOrderingComposer,
          $$DrivesTableAnnotationComposer,
          $$DrivesTableCreateCompanionBuilder,
          $$DrivesTableUpdateCompanionBuilder,
          (
            DriveRow,
            BaseReferences<_$FieldLogDatabase, $DrivesTable, DriveRow>,
          ),
          DriveRow,
          PrefetchHooks Function()
        > {
  $$DrivesTableTableManager(_$FieldLogDatabase db, $DrivesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> contextCode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> sealedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> hasPendingChanges = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DrivesCompanion(
                localId: localId,
                serverId: serverId,
                contextCode: contextCode,
                startedAt: startedAt,
                endedAt: endedAt,
                sealedAt: sealedAt,
                revision: revision,
                isTombstone: isTombstone,
                deletedAt: deletedAt,
                hasPendingChanges: hasPendingChanges,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String contextCode,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> sealedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> hasPendingChanges = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DrivesCompanion.insert(
                localId: localId,
                serverId: serverId,
                contextCode: contextCode,
                startedAt: startedAt,
                endedAt: endedAt,
                sealedAt: sealedAt,
                revision: revision,
                isTombstone: isTombstone,
                deletedAt: deletedAt,
                hasPendingChanges: hasPendingChanges,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DrivesTable, DriveRow>(table),
                  BaseReferences<_$FieldLogDatabase, $DrivesTable, DriveRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DrivesTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $DrivesTable,
      DriveRow,
      $$DrivesTableFilterComposer,
      $$DrivesTableOrderingComposer,
      $$DrivesTableAnnotationComposer,
      $$DrivesTableCreateCompanionBuilder,
      $$DrivesTableUpdateCompanionBuilder,
      (DriveRow, BaseReferences<_$FieldLogDatabase, $DrivesTable, DriveRow>),
      DriveRow,
      PrefetchHooks Function()
    >;
typedef $$TrailLogsTableCreateCompanionBuilder = TrailLogsCompanion Function({
  required String localId,
  Value<String?> serverId,
  required String contextCode,
  required String driveId,
  required String trailCode,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<String?> notes,
  Value<int> revision,
  Value<bool> isTombstone,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$TrailLogsTableUpdateCompanionBuilder = TrailLogsCompanion Function({
  Value<String> localId,
  Value<String?> serverId,
  Value<String> contextCode,
  Value<String> driveId,
  Value<String> trailCode,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String?> notes,
  Value<int> revision,
  Value<bool> isTombstone,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$TrailLogsTableFilterComposer
    extends Composer<_$FieldLogDatabase, $TrailLogsTable> {
  $$TrailLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveId => $composableBuilder(
    column: $table.driveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailCode => $composableBuilder(
    column: $table.trailCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailLogsTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $TrailLogsTable> {
  $$TrailLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveId => $composableBuilder(
    column: $table.driveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailCode => $composableBuilder(
    column: $table.trailCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailLogsTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $TrailLogsTable> {
  $$TrailLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get contextCode => $composableBuilder(
    column: $table.contextCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get driveId =>
      $composableBuilder(column: $table.driveId, builder: (column) => column);

  GeneratedColumn<String> get trailCode =>
      $composableBuilder(column: $table.trailCode, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TrailLogsTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $TrailLogsTable,
          TrailLogRow,
          $$TrailLogsTableFilterComposer,
          $$TrailLogsTableOrderingComposer,
          $$TrailLogsTableAnnotationComposer,
          $$TrailLogsTableCreateCompanionBuilder,
          $$TrailLogsTableUpdateCompanionBuilder,
          (
            TrailLogRow,
            BaseReferences<_$FieldLogDatabase, $TrailLogsTable, TrailLogRow>,
          ),
          TrailLogRow,
          PrefetchHooks Function()
        > {
  $$TrailLogsTableTableManager(_$FieldLogDatabase db, $TrailLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> contextCode = const Value.absent(),
                Value<String> driveId = const Value.absent(),
                Value<String> trailCode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailLogsCompanion(
                localId: localId,
                serverId: serverId,
                contextCode: contextCode,
                driveId: driveId,
                trailCode: trailCode,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
                revision: revision,
                isTombstone: isTombstone,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String contextCode,
                required String driveId,
                required String trailCode,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailLogsCompanion.insert(
                localId: localId,
                serverId: serverId,
                contextCode: contextCode,
                driveId: driveId,
                trailCode: trailCode,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
                revision: revision,
                isTombstone: isTombstone,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrailLogsTable, TrailLogRow>(table),
                  BaseReferences<
                    _$FieldLogDatabase,
                    $TrailLogsTable,
                    TrailLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $TrailLogsTable,
      TrailLogRow,
      $$TrailLogsTableFilterComposer,
      $$TrailLogsTableOrderingComposer,
      $$TrailLogsTableAnnotationComposer,
      $$TrailLogsTableCreateCompanionBuilder,
      $$TrailLogsTableUpdateCompanionBuilder,
      (
        TrailLogRow,
        BaseReferences<_$FieldLogDatabase, $TrailLogsTable, TrailLogRow>,
      ),
      TrailLogRow,
      PrefetchHooks Function()
    >;
typedef $$QueuedOperationsTableCreateCompanionBuilder =
    QueuedOperationsCompanion Function({
      required String operationId,
      required String entityId,
      required EntityKind entity,
      required OperationKind kind,
      required int baseRevision,
      required DateTime capturedAt,
      required DateTime recordedAt,
      Value<String?> dependsOn,
      required String payload,
      Value<OperationState> state,
      Value<int> attempts,
      required DateTime enqueuedAt,
      Value<DateTime?> settledAt,
      Value<PushOutcome?> outcome,
      Value<int?> serverRevision,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$QueuedOperationsTableUpdateCompanionBuilder =
    QueuedOperationsCompanion Function({
      Value<String> operationId,
      Value<String> entityId,
      Value<EntityKind> entity,
      Value<OperationKind> kind,
      Value<int> baseRevision,
      Value<DateTime> capturedAt,
      Value<DateTime> recordedAt,
      Value<String?> dependsOn,
      Value<String> payload,
      Value<OperationState> state,
      Value<int> attempts,
      Value<DateTime> enqueuedAt,
      Value<DateTime?> settledAt,
      Value<PushOutcome?> outcome,
      Value<int?> serverRevision,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$QueuedOperationsTableFilterComposer
    extends Composer<_$FieldLogDatabase, $QueuedOperationsTable> {
  $$QueuedOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntityKind, EntityKind, String> get entity =>
      $composableBuilder(
        column: $table.entity,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<OperationKind, OperationKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OperationState, OperationState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enqueuedAt => $composableBuilder(
    column: $table.enqueuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PushOutcome?, PushOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedOperationsTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $QueuedOperationsTable> {
  $$QueuedOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enqueuedAt => $composableBuilder(
    column: $table.enqueuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedOperationsTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $QueuedOperationsTable> {
  $$QueuedOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntityKind, String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OperationKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OperationState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get enqueuedAt => $composableBuilder(
    column: $table.enqueuedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PushOutcome?, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$QueuedOperationsTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $QueuedOperationsTable,
          QueuedOperationRow,
          $$QueuedOperationsTableFilterComposer,
          $$QueuedOperationsTableOrderingComposer,
          $$QueuedOperationsTableAnnotationComposer,
          $$QueuedOperationsTableCreateCompanionBuilder,
          $$QueuedOperationsTableUpdateCompanionBuilder,
          (
            QueuedOperationRow,
            BaseReferences<
              _$FieldLogDatabase,
              $QueuedOperationsTable,
              QueuedOperationRow
            >,
          ),
          QueuedOperationRow,
          PrefetchHooks Function()
        > {
  $$QueuedOperationsTableTableManager(
    _$FieldLogDatabase db,
    $QueuedOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueuedOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<EntityKind> entity = const Value.absent(),
                Value<OperationKind> kind = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<OperationState> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> enqueuedAt = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                Value<PushOutcome?> outcome = const Value.absent(),
                Value<int?> serverRevision = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedOperationsCompanion(
                operationId: operationId,
                entityId: entityId,
                entity: entity,
                kind: kind,
                baseRevision: baseRevision,
                capturedAt: capturedAt,
                recordedAt: recordedAt,
                dependsOn: dependsOn,
                payload: payload,
                state: state,
                attempts: attempts,
                enqueuedAt: enqueuedAt,
                settledAt: settledAt,
                outcome: outcome,
                serverRevision: serverRevision,
                errorCode: errorCode,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String entityId,
                required EntityKind entity,
                required OperationKind kind,
                required int baseRevision,
                required DateTime capturedAt,
                required DateTime recordedAt,
                Value<String?> dependsOn = const Value.absent(),
                required String payload,
                Value<OperationState> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime enqueuedAt,
                Value<DateTime?> settledAt = const Value.absent(),
                Value<PushOutcome?> outcome = const Value.absent(),
                Value<int?> serverRevision = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedOperationsCompanion.insert(
                operationId: operationId,
                entityId: entityId,
                entity: entity,
                kind: kind,
                baseRevision: baseRevision,
                capturedAt: capturedAt,
                recordedAt: recordedAt,
                dependsOn: dependsOn,
                payload: payload,
                state: state,
                attempts: attempts,
                enqueuedAt: enqueuedAt,
                settledAt: settledAt,
                outcome: outcome,
                serverRevision: serverRevision,
                errorCode: errorCode,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueuedOperationsTable, QueuedOperationRow>(
                    table,
                  ),
                  BaseReferences<
                    _$FieldLogDatabase,
                    $QueuedOperationsTable,
                    QueuedOperationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $QueuedOperationsTable,
      QueuedOperationRow,
      $$QueuedOperationsTableFilterComposer,
      $$QueuedOperationsTableOrderingComposer,
      $$QueuedOperationsTableAnnotationComposer,
      $$QueuedOperationsTableCreateCompanionBuilder,
      $$QueuedOperationsTableUpdateCompanionBuilder,
      (
        QueuedOperationRow,
        BaseReferences<
          _$FieldLogDatabase,
          $QueuedOperationsTable,
          QueuedOperationRow
        >,
      ),
      QueuedOperationRow,
      PrefetchHooks Function()
    >;
typedef $$ConflictsTableCreateCompanionBuilder = ConflictsCompanion Function({
  required String operationId,
  required String entityId,
  required EntityKind entity,
  required String clientPayload,
  required String serverState,
  required int serverRevision,
  required int baseRevision,
  required String errorCode,
  Value<String?> reason,
  required DateTime recordedAt,
  Value<DateTime?> resolvedAt,
  Value<int> rowid,
});
typedef $$ConflictsTableUpdateCompanionBuilder = ConflictsCompanion Function({
  Value<String> operationId,
  Value<String> entityId,
  Value<EntityKind> entity,
  Value<String> clientPayload,
  Value<String> serverState,
  Value<int> serverRevision,
  Value<int> baseRevision,
  Value<String> errorCode,
  Value<String?> reason,
  Value<DateTime> recordedAt,
  Value<DateTime?> resolvedAt,
  Value<int> rowid,
});

class $$ConflictsTableFilterComposer
    extends Composer<_$FieldLogDatabase, $ConflictsTable> {
  $$ConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntityKind, EntityKind, String> get entity =>
      $composableBuilder(
        column: $table.entity,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get clientPayload => $composableBuilder(
    column: $table.clientPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverState => $composableBuilder(
    column: $table.serverState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictsTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $ConflictsTable> {
  $$ConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPayload => $composableBuilder(
    column: $table.clientPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverState => $composableBuilder(
    column: $table.serverState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictsTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $ConflictsTable> {
  $$ConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntityKind, String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get clientPayload => $composableBuilder(
    column: $table.clientPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverState => $composableBuilder(
    column: $table.serverState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$ConflictsTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $ConflictsTable,
          ConflictRow,
          $$ConflictsTableFilterComposer,
          $$ConflictsTableOrderingComposer,
          $$ConflictsTableAnnotationComposer,
          $$ConflictsTableCreateCompanionBuilder,
          $$ConflictsTableUpdateCompanionBuilder,
          (
            ConflictRow,
            BaseReferences<_$FieldLogDatabase, $ConflictsTable, ConflictRow>,
          ),
          ConflictRow,
          PrefetchHooks Function()
        > {
  $$ConflictsTableTableManager(_$FieldLogDatabase db, $ConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<EntityKind> entity = const Value.absent(),
                Value<String> clientPayload = const Value.absent(),
                Value<String> serverState = const Value.absent(),
                Value<int> serverRevision = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<String> errorCode = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion(
                operationId: operationId,
                entityId: entityId,
                entity: entity,
                clientPayload: clientPayload,
                serverState: serverState,
                serverRevision: serverRevision,
                baseRevision: baseRevision,
                errorCode: errorCode,
                reason: reason,
                recordedAt: recordedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String entityId,
                required EntityKind entity,
                required String clientPayload,
                required String serverState,
                required int serverRevision,
                required int baseRevision,
                required String errorCode,
                Value<String?> reason = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion.insert(
                operationId: operationId,
                entityId: entityId,
                entity: entity,
                clientPayload: clientPayload,
                serverState: serverState,
                serverRevision: serverRevision,
                baseRevision: baseRevision,
                errorCode: errorCode,
                reason: reason,
                recordedAt: recordedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConflictsTable, ConflictRow>(table),
                  BaseReferences<
                    _$FieldLogDatabase,
                    $ConflictsTable,
                    ConflictRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $ConflictsTable,
      ConflictRow,
      $$ConflictsTableFilterComposer,
      $$ConflictsTableOrderingComposer,
      $$ConflictsTableAnnotationComposer,
      $$ConflictsTableCreateCompanionBuilder,
      $$ConflictsTableUpdateCompanionBuilder,
      (
        ConflictRow,
        BaseReferences<_$FieldLogDatabase, $ConflictsTable, ConflictRow>,
      ),
      ConflictRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String scope,
      Value<String?> cursor,
      Value<DateTime?> serverTimeAtApply,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> scope,
      Value<String?> cursor,
      Value<DateTime?> serverTimeAtApply,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$FieldLogDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverTimeAtApply => $composableBuilder(
    column: $table.serverTimeAtApply,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverTimeAtApply => $composableBuilder(
    column: $table.serverTimeAtApply,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get serverTimeAtApply => $composableBuilder(
    column: $table.serverTimeAtApply,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $SyncCursorsTable,
          SyncCursorRow,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<
              _$FieldLogDatabase,
              $SyncCursorsTable,
              SyncCursorRow
            >,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$FieldLogDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> serverTimeAtApply = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                scope: scope,
                cursor: cursor,
                serverTimeAtApply: serverTimeAtApply,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> serverTimeAtApply = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                scope: scope,
                cursor: cursor,
                serverTimeAtApply: serverTimeAtApply,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursorRow>(table),
                  BaseReferences<
                    _$FieldLogDatabase,
                    $SyncCursorsTable,
                    SyncCursorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $SyncCursorsTable,
      SyncCursorRow,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$FieldLogDatabase, $SyncCursorsTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $$ReferenceDataTableCreateCompanionBuilder =
    ReferenceDataCompanion Function({
      required String kind,
      required String code,
      Value<String?> label,
      Value<String?> payload,
      Value<DateTime?> fetchedAt,
      Value<int> rowid,
    });
typedef $$ReferenceDataTableUpdateCompanionBuilder =
    ReferenceDataCompanion Function({
      Value<String> kind,
      Value<String> code,
      Value<String?> label,
      Value<String?> payload,
      Value<DateTime?> fetchedAt,
      Value<int> rowid,
    });

class $$ReferenceDataTableFilterComposer
    extends Composer<_$FieldLogDatabase, $ReferenceDataTable> {
  $$ReferenceDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReferenceDataTableOrderingComposer
    extends Composer<_$FieldLogDatabase, $ReferenceDataTable> {
  $$ReferenceDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReferenceDataTableAnnotationComposer
    extends Composer<_$FieldLogDatabase, $ReferenceDataTable> {
  $$ReferenceDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ReferenceDataTableTableManager
    extends
        RootTableManager<
          _$FieldLogDatabase,
          $ReferenceDataTable,
          ReferenceRow,
          $$ReferenceDataTableFilterComposer,
          $$ReferenceDataTableOrderingComposer,
          $$ReferenceDataTableAnnotationComposer,
          $$ReferenceDataTableCreateCompanionBuilder,
          $$ReferenceDataTableUpdateCompanionBuilder,
          (
            ReferenceRow,
            BaseReferences<
              _$FieldLogDatabase,
              $ReferenceDataTable,
              ReferenceRow
            >,
          ),
          ReferenceRow,
          PrefetchHooks Function()
        > {
  $$ReferenceDataTableTableManager(
    _$FieldLogDatabase db,
    $ReferenceDataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferenceDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferenceDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferenceDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReferenceDataCompanion(
                kind: kind,
                code: code,
                label: label,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String code,
                Value<String?> label = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReferenceDataCompanion.insert(
                kind: kind,
                code: code,
                label: label,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReferenceDataTable, ReferenceRow>(table),
                  BaseReferences<
                    _$FieldLogDatabase,
                    $ReferenceDataTable,
                    ReferenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReferenceDataTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldLogDatabase,
      $ReferenceDataTable,
      ReferenceRow,
      $$ReferenceDataTableFilterComposer,
      $$ReferenceDataTableOrderingComposer,
      $$ReferenceDataTableAnnotationComposer,
      $$ReferenceDataTableCreateCompanionBuilder,
      $$ReferenceDataTableUpdateCompanionBuilder,
      (
        ReferenceRow,
        BaseReferences<_$FieldLogDatabase, $ReferenceDataTable, ReferenceRow>,
      ),
      ReferenceRow,
      PrefetchHooks Function()
    >;

class $FieldLogDatabaseManager {
  final _$FieldLogDatabase _db;
  $FieldLogDatabaseManager(this._db);
  $$SightingsTableTableManager get sightings =>
      $$SightingsTableTableManager(_db, _db.sightings);
  $$DrivesTableTableManager get drives =>
      $$DrivesTableTableManager(_db, _db.drives);
  $$TrailLogsTableTableManager get trailLogs =>
      $$TrailLogsTableTableManager(_db, _db.trailLogs);
  $$QueuedOperationsTableTableManager get queuedOperations =>
      $$QueuedOperationsTableTableManager(_db, _db.queuedOperations);
  $$ConflictsTableTableManager get conflicts =>
      $$ConflictsTableTableManager(_db, _db.conflicts);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$ReferenceDataTableTableManager get referenceData =>
      $$ReferenceDataTableTableManager(_db, _db.referenceData);
}
