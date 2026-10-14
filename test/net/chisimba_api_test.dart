import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for the service, answering from the shapes verified by hand
/// against the running Chisimba container.
class _FakeService {
  _FakeService();

  final List<RequestOptions> requests = [];
  int evidenceFetches = 0;
  int loginPosts = 0;
  List<Duration> waits = [];

  Future<void> Function(Duration)? wait;

  Dio dio() {
    final dio = Dio();
    dio.httpClientAdapter = _Adapter(this);
    return dio;
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.service);

  final _FakeService service;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    service.requests.add(options);
    final path = options.path;

    if (path.endsWith('/auth/token') && options.method == 'GET') {
      service.evidenceFetches++;
      return _json(options, {
        'data': {
          'csrf_token': 'c' * 64,
          'issued_at': 1791136194,
          'nonce': 'n' * 32,
          'signature': 's' * 64,
          'minimum_seconds': 1,
          'maximum_seconds': 3600,
        },
        'meta': {'timestamp': '2026-10-04T06:00:00Z'},
      }, 200);
    }

    if (path.endsWith('/auth/token') && options.method == 'POST') {
      service.loginPosts++;
      final body = Map<String, dynamic>.from(options.data as Map);
      if (body['csrf_token'] != 'c' * 64 ||
          body['abuse_signature'] != 's' * 64) {
        return _json(options, {
          'error': 'VALIDATION_FAILED',
          'details': {'csrf_token': 'required'},
        }, 422);
      }
      return _json(options, {
        'data': {
          'user': {
            'id': '1',
            'username': 'admin',
            'email': '',
            'fullname': 'Site Administrator',
            'is_active': 1,
          },
          'tokens': {
            'access_token': 'access.jwt.value',
            'refresh_token': 'refresh.jwt.value',
            'token_type': 'Bearer',
            'expires_in': 3600,
          },
        },
        'meta': {'timestamp': '2026-10-04T06:00:01Z'},
      }, 201);
    }

    if (path.endsWith('/auth/refresh') && options.method == 'POST') {
      final body = Map<String, dynamic>.from(options.data as Map);
      if (body['refresh_token'] != 'refresh.jwt.value' ||
          body['device_id'] != 'device-1') {
        return _json(options, {'error': 'UNAUTHORIZED'}, 401);
      }
      return _json(options, {
        'data': {
          'access_token': 'access.jwt.renewed',
          'refresh_token': 'refresh.jwt.rotated',
          'token_type': 'Bearer',
          'expires_in': 3600,
        },
        'meta': {'timestamp': '2026-10-04T06:00:03Z'},
      }, 200);
    }

    if (path.endsWith('/auth/me')) {
      if (options.headers['Authorization'] != 'Bearer access.jwt.value') {
        return _json(options, {'error': 'UNAUTHORIZED'}, 401);
      }
      return _json(options, {
        'data': {
          'id': '1',
          'username': 'admin',
          'email': '',
          'fullname': 'Site Administrator',
          'is_active': 1,
        },
        'meta': {'timestamp': '2026-10-04T06:00:02Z'},
      }, 200);
    }

    if (path.endsWith('/auth/logout')) {
      return _json(options, {
        'data': {'ok': true},
      }, 200);
    }

    if (path.endsWith('/species') && options.method == 'GET') {
      if (options.headers['Authorization'] != 'Bearer access.jwt.value') {
        return _json(options, {'error': 'UNAUTHORIZED'}, 401);
      }
      // The field service sends this collection bare, not under 'data'
      // (verified by hand against the running container).
      return _json(options, {
        'species': [
          {
            'code': 'ELEP',
            'common_name': 'African Elephant',
            'scientific_name': 'Loxodonta africana',
            'description': 'Largest land mammal.',
          },
        ],
      }, 200);
    }

    return _json(options, {'error': 'NOT_FOUND'}, 404);
  }

  ResponseBody _json(RequestOptions options, Object body, int status) {
    return ResponseBody.fromString(
      _encode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _encode(Object body) => jsonEncode(body);

void main() {
  late _FakeService service;

  ChisimbaApi build() {
    service = _FakeService();
    return ChisimbaApi(
      dio: service.dio(),
      baseUrl: 'http://localhost:8080',
      wait: (d) async => service.waits.add(d),
    );
  }

  group('the two-step sign-in', () {
    test('asks for evidence with a GET and no credentials', () async {
      final api = build();
      final evidence = await api.fetchLoginEvidence();

      final first = service.requests.single;
      expect(first.method, 'GET');
      expect(first.path, endsWith('/api/v1/auth/token'));
      expect(
        first.data,
        isNull,
        reason: 'the evidence request carries no password',
      );

      expect(evidence.csrfToken, 'c' * 64);
      expect(evidence.issuedAt, 1791136194);
      expect(evidence.minimumSeconds, 1);
      expect(evidence.isComplete, isTrue);
    });

    test('posts the evidence flat, with the epoch as an integer', () async {
      final api = build();
      await api.signIn(username: 'admin', password: 'pw');

      final post = service.requests.last;
      expect(post.method, 'POST');
      final body = Map<String, dynamic>.from(post.data as Map);
      expect(
        body.keys,
        containsAll(<String>[
          'username',
          'password',
          'csrf_token',
          'abuse_issued_at',
          'abuse_nonce',
          'abuse_signature',
        ]),
      );
      expect(
        body['abuse_issued_at'],
        isA<int>(),
        reason: 'the service sends an epoch integer, not a timestamp string',
      );
      expect(body['abuse_issued_at'], 1791136194);
      expect(
        body.containsKey('auth'),
        isFalse,
        reason: 'the service does not nest these',
      );
    });

    test('waits out the service minimum before it posts', () async {
      final api = build();
      await api.signIn(username: 'admin', password: 'pw');
      expect(service.waits, [const Duration(seconds: 1)]);
    });

    test('returns the user the login already carried', () async {
      final api = build();
      final session = await api.signIn(username: 'admin', password: 'pw');

      expect(session.isUsable, isTrue);
      expect(session.user.username, 'admin');
      expect(session.user.fullname, 'Site Administrator');
      expect(session.accessToken, 'access.jwt.value');
      expect(session.refreshToken, 'refresh.jwt.value');
      expect(session.user.isActive, isTrue);
    });

    test('carries the device id the refresh will need to match', () async {
      final api = build();
      await api.signIn(username: 'admin', password: 'pw', deviceId: 'device-1');

      final body = Map<String, dynamic>.from(service.requests.last.data as Map);
      expect(
        body['device_id'],
        'device-1',
        reason:
            'the service binds the refresh token to this id and refuses to '
            'rotate it for any other',
      );
    });

    test('omits the device id when none is offered', () async {
      final api = build();
      await api.signIn(username: 'admin', password: 'pw');

      final body = Map<String, dynamic>.from(service.requests.last.data as Map);
      expect(body.containsKey('device_id'), isFalse);
    });
  });

  group('who am I', () {
    test('presents the token as a bearer, not as an api key', () async {
      final api = build();
      final user = await api.whoAmI('access.jwt.value');

      final call = service.requests.single;
      expect(call.path, endsWith('/api/v1/auth/me'));
      expect(call.headers['Authorization'], 'Bearer access.jwt.value');
      expect(
        call.headers.containsKey('X-API-Key'),
        isFalse,
        reason:
            'verified against the service: an access token sent as an '
            'api key is refused with 401',
      );
      expect(user.username, 'admin');
    });
  });

  group('renewing a stale access token', () {
    test('posts the device id and reads the flat, rotated pair', () async {
      final api = build();
      final refreshed = await api.refreshSession(
        refreshToken: 'refresh.jwt.value',
        deviceId: 'device-1',
      );

      final post = service.requests.last;
      final body = Map<String, dynamic>.from(post.data as Map);
      expect(body['refresh_token'], 'refresh.jwt.value');
      expect(
        body['device_id'],
        'device-1',
        reason: 'the service refuses a refresh from another device',
      );
      // The refresh endpoint answers flat under `data`, unlike sign-in which
      // nests the pair under `data.tokens`.
      expect(refreshed.accessToken, 'access.jwt.renewed');
      expect(refreshed.refreshToken, 'refresh.jwt.rotated');
      expect(refreshed.expiresInSeconds, 3600);
    });

    test('a device mismatch is refused as an authorization failure', () async {
      final api = build();
      await expectLater(
        api.refreshSession(
          refreshToken: 'refresh.jwt.value',
          deviceId: 'somebody-elses-phone',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.isUnauthorized,
            'isUnauthorized',
            isTrue,
          ),
        ),
      );
    });
  });

  group('reference lists', () {
    test('species parses when the service sends the bare collection', () async {
      final api = build();
      final list = await api.getSpecies('access.jwt.value');

      expect(list.species, hasLength(1));
      expect(list.species.single.code, 'ELEP');
      expect(list.species.single.commonName, 'African Elephant');
    });

    test(
      'species still parses when the body carries a data envelope',
      () async {
        final api = ChisimbaApi(
          dio: Dio()..httpClientAdapter = _WrappedSpeciesService(),
          baseUrl: 'http://localhost:8080',
          wait: (_) async {},
        );

        final list = await api.getSpecies('any.token');

        expect(list.species, hasLength(1));
        expect(list.species.single.code, 'ELEP');
      },
    );
  });

  group('failures a person can act on', () {
    test('a rejected password says so without asking twice', () async {
      final api = ChisimbaApi(
        dio: Dio()..httpClientAdapter = _RejectingService(),
        baseUrl: 'http://localhost:8080',
        wait: (_) async {},
      );

      await expectLater(
        api.signIn(username: 'admin', password: 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.message,
            'message',
            contains('Sign-in failed'),
          ),
        ),
      );
    });

    test('being unable to reach the service is not a wrong password', () async {
      final api = ChisimbaApi(
        dio: Dio()..httpClientAdapter = _UnreachableService(),
        baseUrl: 'http://localhost:8080',
        wait: (_) async {},
      );

      await expectLater(
        api.fetchLoginEvidence(),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.message,
            'message',
            allOf(
              contains('Could not reach the service'),
              contains('safe on this phone'),
            ),
          ),
        ),
      );
    });
  });

  group('a sync field that came back as a string', () {
    test('push results read as empty instead of crashing the sync', () {
      final response = PushResponse.fromJson({'results': 'oops'});

      expect(response.results, isEmpty);
    });

    test('pull changes read as empty instead of crashing the sync', () {
      final response = PullResponse.fromJson({'changes': 'oops'});

      expect(response.changes, isEmpty);
    });
  });

  group('the session cookie that binds the CSRF token to a session', () {
    test('carries the cookie from the evidence GET to the sign-in POST', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final cookiesOnPost = <String?>[];

      server.listen((request) async {
        await utf8.decoder.bind(request).join();
        final isTokenPath = request.uri.path.endsWith('/auth/token');
        if (request.method == 'GET' && isTokenPath) {
          request.response
            ..statusCode = 200
            ..headers.set(
              HttpHeaders.setCookieHeader,
              'PHPSESSION=abc123; Path=/; HttpOnly; SameSite=Lax',
            )
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'data': {
                  'csrf_token': 'c' * 64,
                  'issued_at': 1,
                  'nonce': 'n',
                  'signature': 's',
                  'minimum_seconds': 1,
                  'maximum_seconds': 3600,
                },
              }),
            );
        } else {
          cookiesOnPost.add(request.headers.value(HttpHeaders.cookieHeader));
          request.response
            ..statusCode = 201
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'data': {
                  'user': {
                    'id': '1',
                    'username': 'admin',
                    'email': '',
                    'fullname': 'Site Administrator',
                    'is_active': 1,
                  },
                  'tokens': {
                    'access_token': 'access.jwt.value',
                    'refresh_token': 'refresh.jwt.value',
                    'token_type': 'Bearer',
                    'expires_in': 3600,
                  },
                },
              }),
            );
        }
        await request.response.close();
      });

      // No injected Dio: this exercises the client's own cookie jar, the path a
      // real device takes. The PHP session cookie the service sets alongside the
      // CSRF evidence has to travel back on the sign-in POST, or the service
      // cannot find the token in any session and answers 401 — which reads like
      // a wrong password.
      final api = ChisimbaApi(
        baseUrl: 'http://127.0.0.1:${server.port}',
        wait: (_) async {},
      );

      final evidence = await api.fetchLoginEvidence();
      final session = await api.signIn(
        username: 'admin',
        password: 'a',
        evidence: evidence,
        deviceId: 'device-1',
      );

      expect(session.isUsable, isTrue);
      expect(
        cookiesOnPost.single,
        contains('PHPSESSION=abc123'),
        reason:
            'the CSRF token is useless without the session it was issued to',
      );
    });
  });

  group('recovering from a stale evidence token', () {
    test('fetches fresh evidence and retries once', () async {
      final service = _StaleEvidenceService();
      final waits = <Duration>[];
      final api = ChisimbaApi(
        dio: Dio()..httpClientAdapter = service,
        baseUrl: 'http://localhost:8080',
        wait: (d) async => waits.add(d),
      );

      final session = await api.signIn(username: 'admin', password: 'a');

      expect(session.isUsable, isTrue);
      expect(
        service.evidenceFetches,
        2,
        reason: 'the stale token has to be replaced before retrying',
      );
      expect(
        service.loginPosts,
        2,
        reason: 'exactly one automatic retry, not an unbounded loop',
      );
      expect(
        waits,
        hasLength(2),
        reason: 'each post waits out the minimum the evidence advertises',
      );
    });

    test(
      'reports the failure after one recovery, not a third attempt',
      () async {
        final service = _StaleEvidenceService(alwaysStale: true);
        final api = ChisimbaApi(
          dio: Dio()..httpClientAdapter = service,
          baseUrl: 'http://localhost:8080',
          wait: (_) async {},
        );

        await expectLater(
          api.signIn(username: 'admin', password: 'a'),
          throwsA(
            isA<AuthFailure>().having(
              (f) => f.message,
              'message',
              contains('expired'),
            ),
          ),
        );
        expect(
          service.loginPosts,
          2,
          reason: 'the client recovers once and then reports the failure',
        );
      },
    );
  });

  group('reading the service error envelope', () {
    Response<dynamic> response(int status, Object data) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/v1/auth/token'),
      statusCode: status,
      data: data,
    );

    test('reads the code, sentence and details one level in under error', () {
      final failure = AuthFailure.fromResponse(
        response(422, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Invalid input',
            'details': {'session_expired': 'stale'},
          },
          'meta': {'timestamp': '2026-10-04T06:00:00Z'},
        }),
      );

      expect(failure.code, 'VALIDATION_ERROR');
      expect(failure.statusCode, 422);
      expect(failure.message, contains('expired'));
    });

    test('a rejected password keeps the service wording and the 401', () {
      final failure = AuthFailure.fromResponse(
        response(401, {
          'error': {
            'code': 'UNAUTHORIZED',
            'message': 'Invalid credentials',
            'details': <dynamic>[],
          },
          'meta': {'timestamp': '2026-10-04T06:00:00Z'},
        }),
      );

      expect(failure.code, 'UNAUTHORIZED');
      expect(failure.isUnauthorized, isTrue);
      expect(failure.message, 'Invalid credentials');
    });
  });
}

class _RejectingService implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET') {
      return _ok({
        'data': {
          'csrf_token': 'c' * 64,
          'issued_at': 1,
          'nonce': 'n',
          'signature': 's',
          'minimum_seconds': 0,
        },
      });
    }
    return ResponseBody.fromString(
      '{"error":"UNAUTHORIZED","details":{"message":"Invalid credentials"}}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnreachableService implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      error: 'connection refused',
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The older contract: collections wrapped in a 'data' envelope.
class _WrappedSpeciesService implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _ok({
      'data': {
        'species': [
          {
            'code': 'ELEP',
            'common_name': 'African Elephant',
            'scientific_name': 'Loxodonta africana',
            'description': 'Largest land mammal.',
          },
        ],
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

/// A service whose credential POST reports the evidence token as no longer
/// bound to the session — the shape a lost session cookie produces — until a
/// fresh token is fetched.
class _StaleEvidenceService implements HttpClientAdapter {
  _StaleEvidenceService({this.alwaysStale = false});

  /// When set, every POST keeps reporting stale evidence, so the client has to
  /// give up rather than spin.
  final bool alwaysStale;
  int evidenceFetches = 0;
  int loginPosts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET') {
      evidenceFetches++;
      return _jsonResponse(200, {
        'data': {
          'csrf_token': 'c' * 64,
          'issued_at': 1,
          'nonce': 'n',
          'signature': 's',
          'minimum_seconds': 1,
        },
      });
    }
    loginPosts++;
    if (alwaysStale || loginPosts == 1) {
      return _jsonResponse(422, {
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid input',
          'details': {'session_expired': 'stale evidence token'},
        },
        'meta': {'timestamp': '2026-10-04T06:00:00Z'},
      });
    }
    return _jsonResponse(201, {
      'data': {
        'user': {
          'id': '1',
          'username': 'admin',
          'email': '',
          'fullname': 'Site Administrator',
          'is_active': 1,
        },
        'tokens': {
          'access_token': 'access.jwt.value',
          'refresh_token': 'refresh.jwt.value',
          'token_type': 'Bearer',
          'expires_in': 3600,
        },
      },
      'meta': {'timestamp': '2026-10-04T06:00:01Z'},
    });
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int status, Object body) => ResponseBody.fromString(
  _encode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

ResponseBody _ok(Object body) => ResponseBody.fromString(
  _encode(body),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
