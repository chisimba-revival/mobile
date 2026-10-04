import 'dart:convert';
import 'dart:io';

import 'package:field_log/net/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('session_store');
    file = File('${directory.path}/session.json');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  StoredTokens aToken([String access = 'access-abc']) => StoredTokens(
    accessToken: access,
    refreshToken: 'refresh-xyz',
    expiresInSeconds: 3600,
  );

  test('a session survives being written and read back', () async {
    final store = SessionStore(file: file);
    await store.write(aToken());

    final read = await store.read();

    expect(read, isNotNull);
    expect(read!.accessToken, 'access-abc');
    expect(read.refreshToken, 'refresh-xyz');
    expect(read.expiresInSeconds, 3600);
  });

  test('the file holds only the tokens, not a copy of the user', () async {
    final store = SessionStore(file: file);
    await store.write(aToken());

    final written =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    // A stored user would go stale the moment the service renamed or disabled
    // the account, and it would be a record of somebody sitting in the logbook.
    expect(written.containsKey('user'), isFalse);
    expect(written.keys, containsAll(['access_token', 'refresh_token']));
  });

  test('no file at all is no session, not an error', () async {
    expect(await SessionStore(file: file).read(), equals(null));
  });

  test('an empty file is no session', () async {
    await file.writeAsString('');
    expect(await SessionStore(file: file).read(), equals(null));
  });

  test('a half-written file is no session rather than a crash', () async {
    // What an interrupted write actually leaves behind.
    await file.writeAsString('{"version": 1, "access_tok');

    expect(await SessionStore(file: file).read(), equals(null));
  });

  test('a file holding something else entirely is no session', () async {
    await file.writeAsString('[1, 2, 3]');
    expect(await SessionStore(file: file).read(), equals(null));
  });

  test('a file with an empty access token is not usable', () async {
    // Truncation can leave a parseable object with the credential missing.
    await file.writeAsString(
      jsonEncode({'access_token': '', 'refresh_token': 'refresh-xyz'}),
    );

    expect(await SessionStore(file: file).read(), equals(null));
  });

  test('signing out removes the file', () async {
    final store = SessionStore(file: file);
    await store.write(aToken());
    expect(await file.exists(), isTrue);

    await store.clear();

    expect(await file.exists(), isFalse);
    expect(await store.read(), equals(null));
  });

  test('signing out twice is not an error', () async {
    final store = SessionStore(file: file);
    await store.clear();
    await store.clear();
    expect(await file.exists(), isFalse);
  });

  test('the file is created when its directory is missing', () async {
    final nested = File('${directory.path}/deeper/session.json');
    await SessionStore(file: nested).write(aToken());

    expect(await nested.exists(), isTrue);
    expect(
      (await SessionStore(file: nested).read())!.accessToken,
      'access-abc',
    );
  });
}
