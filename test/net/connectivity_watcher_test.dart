import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:field_log/net/connectivity_watcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// A check that blows up the way desktop Linux does when NetworkManager is
/// not running: the point is that the app must not crash over a radio it
/// cannot see.
class _ThrowingProbe implements TransportProbe {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    throw StateError(
      'The name org.freedesktop.NetworkManager was not '
      'provided by any .service files',
    );
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

class _WifiProbe implements TransportProbe {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

void main() {
  test(
    'a broken platform check reports no signal rather than crashing',
    () async {
      final watcher = ConnectivityWatcher(probe: _ThrowingProbe());

      final status = await watcher.current();

      expect(status.hasTransport, isFalse);
      expect(status.transports, isEmpty);
    },
  );

  test(
    'a healthy platform check still reports the transports it sees',
    () async {
      final watcher = ConnectivityWatcher(probe: _WifiProbe());

      final status = await watcher.current();

      expect(status.hasTransport, isTrue);
      expect(status.transports, ['wifi']);
    },
  );

  test('watch() yields a no-signal first value instead of throwing', () async {
    final watcher = ConnectivityWatcher(probe: _ThrowingProbe());

    final first = await watcher.watch().first;

    expect(first.hasTransport, isFalse);
  });
}
