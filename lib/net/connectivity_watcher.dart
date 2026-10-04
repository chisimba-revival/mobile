import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the service might be reachable.
///
/// [online] is a necessary condition, not a sufficient one, and the difference
/// is the whole reason this class exists as its own type rather than a bool
/// passed around. A phone attached to a cell tower with no data plan, or
/// sitting behind a captive portal in a lodge, reports wifi or mobile while
/// every request fails. Connectivity is transport, not reachability.
///
/// So nothing here decides that a queued change will send. Only a successful
/// request proves that, and the push engine already treats a failure as a
/// deferral rather than a loss. What this source is for is honesty in the
/// interface: the chip says "no signal" only when there is genuinely no
/// transport, and the tile layer skips the network when there is none, rather
/// than making every tile wait out a timeout.
class ConnectivityStatus {
  const ConnectivityStatus({
    required this.hasTransport,
    required this.transports,
  });

  /// No transport at all. This is the only state that is definitely offline.
  final bool hasTransport;

  /// The transports currently reported, for the interface to name plainly.
  final List<String> transports;

  /// What the reader is told. Deliberately phrased as "no signal" rather than
  /// "offline": the client cannot know it is offline, only that it has no
  /// radio.
  String get label => hasTransport ? 'Signal' : 'No signal';

  @override
  bool operator ==(Object other) =>
      other is ConnectivityStatus &&
      other.hasTransport == hasTransport &&
      other.transports.length == transports.length;

  @override
  int get hashCode => Object.hash(hasTransport, transports.length);
}

/// Watches connectivity and reports it as a stream.
///
/// Injected rather than constructed so a screen or the app root can be built
/// and tested with a known status and no platform channel behind it.
class ConnectivityWatcher {
  ConnectivityWatcher({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// The current status, and every change to it.
  ///
  /// The first value is the status at the time of subscribing, so a caller
  /// never has to ask separately and race against the first change.
  Stream<ConnectivityStatus> watch() async* {
    yield await current();
    yield* _connectivity.onConnectivityChanged.map(_describe);
  }

  /// The status now.
  Future<ConnectivityStatus> current() async =>
      _describe(await _connectivity.checkConnectivity());

  ConnectivityStatus _describe(List<ConnectivityResult> results) {
    // The list is not an or: a device can hold wifi and mobile at once, and
    // the empty list is the only thing that means no transport.
    final names = <String>[
      for (final result in results)
        switch (result) {
          ConnectivityResult.wifi => 'wifi',
          ConnectivityResult.mobile => 'mobile',
          ConnectivityResult.ethernet => 'ethernet',
          ConnectivityResult.vpn => 'vpn',
          ConnectivityResult.satellite => 'satellite',
          ConnectivityResult.bluetooth => 'bluetooth',
          ConnectivityResult.other => 'other',
          ConnectivityResult.none => 'none',
        },
    ];
    final hasTransport =
        names.isNotEmpty && !names.every((name) => name == 'none');
    return ConnectivityStatus(hasTransport: hasTransport, transports: names);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
