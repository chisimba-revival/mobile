import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Where a signed-in session is kept between launches.
///
/// A refresh token is a credential, so it is written owner-only where the
/// platform allows it, and read back defensively. A file that exists but cannot
/// be parsed is treated as no session rather than an error: the worst outcome of
/// a corrupt credential file is being asked to sign in again, and refusing to
/// start because of one would turn a nuisance into a dead app.
///
/// This deliberately is not in the Drift store. That database is the logbook: it
/// is synced, exportable and holds records that outlive the account. A
/// credential beside a sighting is one export away from being handed to whoever
/// the logbook is handed to.
///
/// Only the tokens are stored. The user is re-read from the service on restore,
/// which means a renamed account or a revoked permission shows as it is now
/// rather than as it was cached, and it means the file holds nothing but the two
/// strings that are actually credentials.
class SessionStore {
  SessionStore({required this.file});

  final File file;

  Future<StoredTokens?> read() async {
    try {
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final tokens = StoredTokens(
        accessToken: '${json['access_token'] ?? ''}',
        refreshToken: '${json['refresh_token'] ?? ''}',
        expiresInSeconds: switch (json['expires_in']) {
          final num value => value.toInt(),
          _ => null,
        },
      );
      return tokens.isUsable ? tokens : null;
    } on Object catch (error) {
      debugPrint('Stored session could not be read: $error');
      return null;
    }
  }

  Future<void> write(StoredTokens tokens) async {
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'access_token': tokens.accessToken,
        'refresh_token': tokens.refreshToken,
        'expires_in': tokens.expiresInSeconds,
      }),
      flush: true,
    );
    if (!Platform.isWindows) {
      // Done after the write because Dart cannot create a file with a mode, so
      // the file exists briefly under the process umask. Tightening afterwards
      // is a window rather than a guarantee, but it is the only one available
      // without a native dependency.
      try {
        await Process.run('chmod', ['600', file.path]);
      } on ProcessException catch (error) {
        debugPrint('Session file could not be restricted: $error');
      }
    }
  }

  /// Forget the session. Used on sign-out, and when the service says the token
  /// is no longer accepted.
  Future<void> clear() async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (error) {
      // Failing to remove a credential is worth reporting, but it is not a
      // reason to stop the trainee recording what they saw.
      debugPrint('Stored session could not be removed: $error');
    }
  }
}

/// The two strings that are credentials, and nothing else.
///
/// A user record is not persisted: it is fetched from the service each time,
/// so what the app shows is what the service says now.
class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresInSeconds,
  });

  /// Present so that an interrupted write, which truncates, is detected as no
  /// session rather than sent to the service as an empty bearer.
  static const empty = '';

  final String accessToken;
  final String refreshToken;
  final int? expiresInSeconds;

  bool get isUsable => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}
