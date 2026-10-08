import 'package:dio/dio.dart';

import '../models/sync_operation.dart';

/// The signed-in person, as the service describes them.
///
/// A plain value rather than a row or a map, so a screen can be built and
/// tested without a network or a database. Every field is nullable except
/// [id], because a service is free to omit what it does not hold and a missing
/// full name is not a reason to refuse to sign in.
class FieldUser {
  const FieldUser({
    required this.id,
    required this.username,
    this.fullname,
    this.email,
    this.isActive,
    this.grants,
    this.activeContext,
  });

  factory FieldUser.fromJson(Map<String, dynamic> json) => FieldUser(
    id: '${json['id'] ?? ''}',
    username: '${json['username'] ?? ''}',
    fullname: _textOrNull(json['fullname']),
    email: _textOrNull(json['email']),
    // The service sends an integer, not a boolean. Anything absent is treated
    // as active rather than refused: the account exists and was authenticated,
    // and a client that locks a signed-in person out over a missing flag is
    // worse than one that trusts a successful sign-in.
    isActive: switch (json['is_active']) {
      final bool value => value,
      final num value => value != 0,
      final String value => value != '0' && value.isNotEmpty,
      _ => null,
    },
    grants: (json['grants'] as List<dynamic>?)?.map((e) => '$e').toList(),
    activeContext: _textOrNull(json['active_context'] ?? json['ctx']),
  );

  final String id;
  final String username;
  final String? fullname;
  final String? email;
  final bool? isActive;
  final List<String>? grants;
  final String? activeContext;

  /// What to call the person. The full name if the service has one, otherwise
  /// the username, and never an empty string, because a blank chip in the
  /// corner of a field log tells nobody who is holding the phone.
  String get displayName {
    final name = fullname?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return username.isEmpty ? 'Signed in' : username;
  }

  /// The first name on its own, for a greeting that fits a narrow header.
  String get shortName {
    final name = fullname?.trim();
    if (name != null && name.isNotEmpty) {
      return name.split(RegExp(r'\s+')).first;
    }
    return username.isEmpty ? 'there' : username;
  }

  /// Whether this user has the field:write grant.
  bool get canWriteField => grants?.contains('field:write') ?? false;
}

Map<String, dynamic> _mapOrEmpty(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String? _textOrNull(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// A signed-in session: who, and the two tokens.
class FieldSession {
  const FieldSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresInSeconds,
  });

  factory FieldSession.fromLoginResponse(Map<String, dynamic> data) {
    final tokens = _mapOrEmpty(data['tokens']);
    return FieldSession(
      user: FieldUser.fromJson(_mapOrEmpty(data['user'])),
      accessToken: '${tokens['access_token'] ?? ''}',
      refreshToken: '${tokens['refresh_token'] ?? ''}',
      expiresInSeconds: switch (tokens['expires_in']) {
        final num value => value.toInt(),
        _ => null,
      },
    );
  }

  final FieldUser user;
  final String accessToken;
  final String refreshToken;
  final int? expiresInSeconds;

  /// A session with no access token is not a session. Signing in and being
  /// handed nothing is a failure the caller has to hear about rather than
  /// discover on its first authenticated request.
  bool get isUsable => accessToken.isNotEmpty && user.id.isNotEmpty;
}

/// What went wrong, in words a person can act on.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  /// The message shown on a sign-in failure.
  ///
  /// The service distinguishes a wrong password from expired abuse evidence,
  /// from a honeypot hit and from rate limiting, and deliberately does not say
  /// which account exists. This does not second-guess it: a failed sign-in is
  /// reported as a failed sign-in, with the service's own words when it gives
  /// them, and the caller is not told whether the username was real.
  @override
  String toString() => message;

  factory AuthFailure.fromResponse(Response<dynamic> response) {
    final body = response.data;
    final code = body is Map ? body['error'] : null;
    final details = body is Map ? body['details'] : null;

    final parts = <String>[];
    if (details is Map && details['retryAfter'] != null) {
      parts.add('Try again in ${details['retryAfter']} seconds.');
    }
    if (details is Map && details['abuse_evidence'] != null) {
      parts.add('The security token expired. Start again.');
    }
    if (details is Map && details['website'] != null) {
      parts.add('That request did not look like it came from this app.');
    }
    if (parts.isEmpty) {
      // Not the code. A raw 'UNAUTHORIZED' on a phone in a vehicle is not a
      // message, it is a shrug. The code is kept in `code` for the caller that
      // wants to branch on it; the sentence is for the person holding the phone.
      parts.add('Sign-in failed. Check the name and password and try again.');
    }
    return AuthFailure(parts.join(' '), code: code is String ? code : null);
  }

  factory AuthFailure.network(Object error) => AuthFailure(
    'Could not reach the service. Everything recorded is safe on this '
    'phone and goes on its own when there is signal.',
  );
}

/// The evidence the service hands out before it will accept a password.
///
/// Fetched by a bodyless GET. This is not an assumption: sending credentials to
/// the POST without it returns 422 naming all four missing fields.
class LoginEvidence {
  const LoginEvidence({
    required this.csrfToken,
    required this.issuedAt,
    required this.nonce,
    required this.signature,
    required this.minimumSeconds,
  });

  factory LoginEvidence.fromJson(Map<String, dynamic> json) => LoginEvidence(
    csrfToken: '${json['csrf_token'] ?? ''}',
    // An epoch integer, not an ISO string.
    issuedAt: switch (json['issued_at']) {
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    },
    nonce: '${json['nonce'] ?? ''}',
    signature: '${json['signature'] ?? ''}',
    minimumSeconds: switch (json['minimum_seconds']) {
      final num value => value.toInt(),
      _ => 1,
    },
  );

  final String csrfToken;
  final int issuedAt;
  final String nonce;
  final String signature;
  final int minimumSeconds;

  bool get isComplete =>
      csrfToken.isNotEmpty && nonce.isNotEmpty && signature.isNotEmpty;
}

/// Remembers the session cookie across requests on the client's own Dio.
///
/// The service binds the CSRF token it hands out with the login evidence to
/// the PHP session cookie set on that same response. A client that drops the
/// cookie sends back a token the server cannot find in any session, and gets
/// a 401 that reads exactly like a wrong password — which is worse than a
/// clear error, because the person starts hunting for a typo they do not
/// have. dart:io's HttpClient does not carry cookies for us; this does.
class _SessionCookieJar extends Interceptor {
  final Map<String, String> _cookies = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_cookies.isNotEmpty) {
      options.headers['cookie'] = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final setCookies = response.headers['set-cookie'];
    if (setCookies != null) {
      for (final raw in setCookies) {
        // Only the first segment is name=value; the rest are attributes
        // (Path, HttpOnly, SameSite) that never belong in a request header.
        final pair = raw.split(';').first.trim();
        final eq = pair.indexOf('=');
        if (eq <= 0) continue;
        final name = pair.substring(0, eq).trim();
        final value = pair.substring(eq + 1).trim();
        if (value.isEmpty) {
          _cookies.remove(name);
        } else {
          _cookies[name] = value;
        }
      }
    }
    handler.next(response);
  }
}

/// Talks to the Chisimba field guiding service.
///
/// The service is not reachable from a device until it is deployed, so every
/// failure here is treated as a possibility rather than an exception. A client
/// that cannot sign in still has to record what the trainee saw.
class ChisimbaApi {
  ChisimbaApi({
    Dio? dio,
    required this.baseUrl,
    Future<void> Function(Duration)? wait,
  }) : _dio = dio ?? (Dio()..interceptors.add(_SessionCookieJar())),
       _wait = wait ?? Future<void>.delayed;

  final Dio _dio;
  final Future<void> Function(Duration) _wait;

  /// The service root, without the version. The version is part of every path
  /// so a future v2 is a different client rather than a different branch
  /// through the same one.
  ///
  /// Mutable so the office address can be corrected on the sign-in screen: a
  /// field device is pointed at whichever server the reserve actually runs,
  /// and that is not known at build time. Cookies from the previous server are
  /// harmless on the next one — the first response overwrites them by name.
  String baseUrl;

  String _path(String path) => '$baseUrl$path';

  /// Ask for the evidence a password will be accepted against.
  Future<LoginEvidence> fetchLoginEvidence() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path('/api/v1/auth/login'),
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure(
          'Sign-in is unavailable: the service sent back something unreadable.',
        );
      }
      return LoginEvidence.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// Sign in, waiting out the service's own minimum interval first.
  ///
  /// Waiting less produces a 422 that reads like a rejected password, which is
  /// the sort of error that sends a person hunting for a typo they do not have.
  Future<FieldSession> signIn({
    required String username,
    required String password,
    LoginEvidence? evidence,
  }) async {
    final proof = evidence ?? await fetchLoginEvidence();
    if (!proof.isComplete) {
      throw const AuthFailure(
        'Sign-in is unavailable: the service did not send the security token '
        'a password has to be checked against.',
      );
    }
    if (proof.minimumSeconds > 0) {
      await _wait(Duration(seconds: proof.minimumSeconds));
    }

    try {
      // Flat, deliberately. The service does not nest these.
      final response = await _dio.post<Map<String, dynamic>>(
        _path('/api/v1/auth/login'),
        data: <String, dynamic>{
          'username': username,
          'password': password,
          'csrf_token': proof.csrfToken,
          'abuse_issued_at': proof.issuedAt,
          'abuse_nonce': proof.nonce,
          'abuse_signature': proof.signature,
        },
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure(
          'Sign-in failed: the service sent back something unreadable.',
        );
      }
      final session = FieldSession.fromLoginResponse(data);
      if (!session.isUsable) {
        throw const AuthFailure('Sign-in failed: no usable token came back.');
      }
      return session;
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// Who a stored token belongs to.
  ///
  /// This is the call that restores a session after the app is closed, and it
  /// is the only place the client proves a token still works. A 401 here means
  /// the stored token is dead and the person has to sign in again, which is a
  /// different thing from being offline.
  Future<FieldUser> whoAmI(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path('/api/v1/auth/me'),
        options: Options(
          headers: <String, dynamic>{
            // Bearer, not X-API-Key. Verified: an access token presented as an
            // API key is refused with 401, because they are different
            // credentials.
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Could not read who is signed in.');
      }
      return FieldUser.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// End the session. Never throws: a failure to log out is not worth an error
  /// the person has to dismiss on their way out of a vehicle.
  Future<void> signOut(String refreshToken) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        _path('/api/v1/auth/logout'),
        data: <String, dynamic>{'refresh_token': refreshToken},
      );
    } on DioException {
      return;
    }
  }

  /// Refresh the access token using the refresh token.
  ///
  /// Returns a new FieldSession with fresh tokens, or throws AuthFailure
  /// if the refresh token is expired or invalid.
  Future<FieldSession> refreshSession(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path('/api/v1/auth/refresh'),
        data: <String, dynamic>{'refresh_token': refreshToken},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Token refresh failed: unreadable response.');
      }
      final session = FieldSession.fromLoginResponse(data);
      if (!session.isUsable) {
        throw const AuthFailure(
          'Token refresh failed: no usable token returned.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  AuthFailure _asFailure(DioException error) {
    final response = error.response;
    if (response == null) {
      return AuthFailure.network(error);
    }
    return AuthFailure.fromResponse(response);
  }

  /// GET /api/v1/species
  Future<SpeciesList> getSpecies(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path('/api/v1/species'),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      // The field service returns some collections bare ({'species': [...]})
      // and some wrapped ({'data': [...]}); accept either, like pull does.
      final data = response.data?['data'] ?? response.data;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Could not read species list.');
      }
      return SpeciesList.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// GET /api/v1/competencies
  Future<CompetencyList> getCompetencies(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path('/api/v1/competencies'),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data?['data'] ?? response.data;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Could not read competencies list.');
      }
      return CompetencyList.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// GET /api/v1/outings
  Future<OutingList> getOutings(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path('/api/v1/outings'),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data?['data'] ?? response.data;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Could not read outings list.');
      }
      return OutingList.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// POST /api/v1/sync/push
  Future<PushResponse> push(String accessToken, PushRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path('/api/v1/sync/push'),
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data?['data'] ?? response.data;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Could not read push response.');
      }
      return PushResponse.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }

  /// POST /api/v1/sync/pull
  Future<PullResponse> pull(String accessToken, PullRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path('/api/v1/sync/pull'),
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data?['data'] ?? response.data;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure('Could not read pull response.');
      }
      return PullResponse.fromJson(data);
    } on DioException catch (error) {
      throw _asFailure(error);
    }
  }
}

/// Species reference data from the service.
class SpeciesList {
  const SpeciesList({required this.species});

  factory SpeciesList.fromJson(Map<String, dynamic> json) => SpeciesList(
    species: (json['species'] as List<dynamic>? ?? const [])
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final List<Species> species;
}

/// A species from the reference catalogue.
class Species {
  const Species({
    required this.code,
    required this.commonName,
    required this.scientificName,
    required this.description,
  });

  factory Species.fromJson(Map<String, dynamic> json) => Species(
    code: '${json['code'] ?? ''}',
    commonName: '${json['common_name'] ?? ''}',
    scientificName: '${json['scientific_name'] ?? ''}',
    description: '${json['description'] ?? ''}',
  );

  final String code;
  final String commonName;
  final String scientificName;
  final String description;
}

/// Competency reference data from the service.
class CompetencyList {
  const CompetencyList({required this.competencies});

  factory CompetencyList.fromJson(Map<String, dynamic> json) => CompetencyList(
    competencies: (json['competencies'] as List<dynamic>? ?? const [])
        .map((e) => Competency.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final List<Competency> competencies;
}

/// A competency from the reference catalogue.
class Competency {
  const Competency({
    required this.code,
    required this.name,
    required this.category,
    required this.level,
    required this.description,
    required this.retired,
  });

  factory Competency.fromJson(Map<String, dynamic> json) => Competency(
    code: '${json['code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    category: '${json['category'] ?? ''}',
    level: switch (json['level']) {
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    },
    description: '${json['description'] ?? ''}',
    retired: switch (json['retired']) {
      final bool v => v,
      final String v => v == 'true',
      _ => false,
    },
  );

  final String code;
  final String name;
  final String category;
  final int level;
  final String description;
  final bool retired;
}

/// Outings reference data from the service.
class OutingList {
  const OutingList({required this.outings});

  factory OutingList.fromJson(Map<String, dynamic> json) => OutingList(
    outings: (json['outings'] as List<dynamic>? ?? const [])
        .map((e) => Outing.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final List<Outing> outings;
}

/// An outing from the reference catalogue.
class Outing {
  const Outing({
    required this.id,
    required this.kind,
    required this.contextCode,
    required this.guideId,
    required this.traineeIds,
    required this.status,
    required this.plannedStart,
    this.endedAt,
    this.sealedAt,
    this.notes,
    required this.revision,
  });

  factory Outing.fromJson(Map<String, dynamic> json) => Outing(
    id: '${json['id'] ?? ''}',
    kind: '${json['kind'] ?? ''}',
    contextCode: '${json['context_code'] ?? ''}',
    guideId: '${json['guide_id'] ?? ''}',
    traineeIds:
        (json['trainee_ids'] as List<dynamic>?)?.map((e) => '$e').toList() ??
        [],
    status: '${json['status'] ?? ''}',
    plannedStart: '${json['planned_start'] ?? ''}',
    endedAt: json['ended_at'] as String?,
    sealedAt: json['sealed_at'] as String?,
    notes: json['notes'] as String?,
    revision: switch (json['revision']) {
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    },
  );

  final String id;
  final String kind;
  final String contextCode;
  final String guideId;
  final List<String> traineeIds;
  final String status;
  final String plannedStart;
  final String? endedAt;
  final String? sealedAt;
  final String? notes;
  final int revision;
}

/// Push request to the service.
class PushRequest {
  const PushRequest({required this.operations});

  factory PushRequest.fromJson(Map<String, dynamic> json) => PushRequest(
    operations: (json['operations'] as List<dynamic>? ?? const [])
        .map((e) => PushOperation.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final List<PushOperation> operations;

  Map<String, dynamic> toJson() => {
    'operations': operations.map((e) => e.toJson()).toList(),
  };
}

/// One operation in a push request.
class PushOperation {
  const PushOperation({
    required this.operationId,
    required this.entity,
    required this.kind,
    required this.entityId,
    required this.baseRevision,
    required this.capturedAt,
    required this.recordedAt,
    this.dependsOn,
    required this.payload,
  });

  factory PushOperation.fromJson(Map<String, dynamic> json) => PushOperation(
    operationId: '${json['operation_id'] ?? ''}',
    entity: '${json['entity'] ?? ''}',
    kind: '${json['kind'] ?? ''}',
    entityId: '${json['entity_id'] ?? ''}',
    baseRevision: json['base_revision'] as int?,
    capturedAt: '${json['captured_at'] ?? ''}',
    recordedAt: '${json['recorded_at'] ?? ''}',
    dependsOn: (json['depends_on'] as List<dynamic>?)
        ?.map((e) => '$e')
        .toList(),
    payload: (json['payload'] as Map<String, dynamic>? ?? const {}),
  );

  final String operationId;
  final String entity;
  final String kind;
  final String entityId;
  final int? baseRevision;
  final String capturedAt;
  final String recordedAt;
  final List<String>? dependsOn;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'entity': entity,
    'kind': kind,
    'entity_id': entityId,
    if (baseRevision != null) 'base_revision': baseRevision,
    'captured_at': capturedAt,
    'recorded_at': recordedAt,
    if (dependsOn != null && dependsOn!.isNotEmpty) 'depends_on': dependsOn,
    'payload': payload,
  };
}

/// Push response from the service.
class PushResponse {
  const PushResponse({required this.results});

  factory PushResponse.fromJson(Map<String, dynamic> json) => PushResponse(
    results: (json['results'] as List<dynamic>? ?? const [])
        .map((e) => PushResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final List<PushResult> results;
}

/// One result from a push operation.
class PushResult {
  const PushResult({
    required this.operationId,
    required this.entity,
    required this.entityId,
    required this.outcome,
    this.newRevision,
    this.errorCode,
    this.serverState,
    this.serverRevision,
  });

  factory PushResult.fromJson(Map<String, dynamic> json) => PushResult(
    operationId: '${json['operation_id'] ?? ''}',
    entity: '${json['entity'] ?? ''}',
    entityId: '${json['entity_id'] ?? ''}',
    outcome: '${json['outcome'] ?? ''}',
    newRevision: json['new_revision'] as int?,
    errorCode: json['error_code'] as String?,
    serverState: (json['server_state'] as Map<String, dynamic>?),
    serverRevision: json['server_revision'] as int?,
  );

  final String operationId;
  final String entity;
  final String entityId;
  final String outcome;
  final int? newRevision;
  final String? errorCode;
  final Map<String, dynamic>? serverState;
  final int? serverRevision;
}

/// Pull request to the service.
class PullRequest {
  const PullRequest({required this.cursor});

  factory PullRequest.fromJson(Map<String, dynamic> json) =>
      PullRequest(cursor: '${json['cursor'] ?? ''}');

  final String cursor;

  Map<String, dynamic> toJson() => {'cursor': cursor};
}

/// Pull response from the service.
class PullResponse {
  const PullResponse({
    required this.status,
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
    required this.serverTime,
  });

  factory PullResponse.fromJson(Map<String, dynamic> json) => PullResponse(
    status: '${json['status'] ?? ''}',
    changes: (json['changes'] as List<dynamic>? ?? const [])
        .map((e) => ApiPullChange.fromJson(e as Map<String, dynamic>))
        .toList(),
    nextCursor: json['next_cursor'] as String?,
    hasMore: switch (json['has_more']) {
      final bool v => v,
      final String v => v == 'true',
      _ => false,
    },
    serverTime:
        DateTime.tryParse('${json['server_time'] ?? ''}') ??
        DateTime.now().toUtc(),
  );

  final String status;
  final List<ApiPullChange> changes;
  final String? nextCursor;
  final bool hasMore;
  final DateTime serverTime;

  /// Convert to the internal PullPage model used by PullEngine.
  PullPage toPage() => PullPage(
    changes: changes.map((c) => c.toPullChange()).toList(),
    nextCursor: nextCursor,
    hasMore: hasMore,
    serverTime: serverTime,
    status: status,
  );
}

/// One change from a pull response (API format).
class ApiPullChange {
  const ApiPullChange({
    required this.entityType,
    required this.entityId,
    required this.revision,
    required this.changedAt,
    required this.body,
  });

  factory ApiPullChange.fromJson(Map<String, dynamic> json) => ApiPullChange(
    entityType: '${json['entity_type'] ?? ''}',
    entityId: '${json['entity_id'] ?? ''}',
    revision: switch (json['revision']) {
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    },
    changedAt:
        DateTime.tryParse('${json['changed_at'] ?? ''}') ??
        DateTime.now().toUtc(),
    body: (json['body'] as Map<String, dynamic>? ?? const {}),
  );

  final String entityType;
  final String entityId;
  final int revision;
  final DateTime changedAt;
  final Map<String, dynamic> body;

  /// Convert to the internal PullChange model used by PullEngine.
  PullChange toPullChange() => PullChange(
    entity: EntityKind.values.firstWhere(
      (e) => e.name == entityType,
      orElse: () => EntityKind.sighting,
    ),
    entityId: entityId,
    revision: revision,
    isTombstone: body['deleted_at'] != null,
    state: body,
  );
}
