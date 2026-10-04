import 'package:dio/dio.dart';

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
  );

  final String id;
  final String username;
  final String? fullname;
  final String? email;
  final bool? isActive;

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
  }) : _dio = dio ?? Dio(),
       _wait = wait ?? Future<void>.delayed;

  final Dio _dio;
  final Future<void> Function(Duration) _wait;

  /// The service root, without the version. The version is part of every path
  /// so a future v2 is a different client rather than a different branch
  /// through the same one.
  final String baseUrl;

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

  AuthFailure _asFailure(DioException error) {
    final response = error.response;
    if (response == null) {
      return AuthFailure.network(error);
    }
    return AuthFailure.fromResponse(response);
  }
}
