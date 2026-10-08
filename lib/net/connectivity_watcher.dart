import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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

/// The bare plugin surface the watcher needs.
///
/// Owned here rather than using `Connectivity` directly so a test can
/// substitute a known source (including one whose check throws) without
/// swapping the plugin's platform instance.
abstract class TransportProbe {
  Future<List<ConnectivityResult>> checkConnectivity();

  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class _PluginProbe implements TransportProbe {
  _PluginProbe([Connectivity? plugin]) : _plugin = plugin ?? Connectivity();

  final Connectivity _plugin;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _plugin.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _plugin.onConnectivityChanged;
}

/// A probe that forces a specific connectivity status, for dev/debug use.
class _ForcedProbe implements TransportProbe {
  _ForcedProbe(this._status);

  ConnectivityStatus _status;
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  void update(ConnectivityStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      _toResults(_status);

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream.map(_toResults);

  List<ConnectivityResult> _toResults(ConnectivityStatus status) {
    if (!status.hasTransport) {
      return [ConnectivityResult.none];
    }
    // Default to wifi for forced online; the UI only cares about hasTransport.
    return [ConnectivityResult.wifi];
  }

  void dispose() {
    _controller.close();
  }
}

/// Watches connectivity and reports it as a stream.
///
/// Injected rather than constructed so a screen or the app root can be built
/// and tested with a known status and no platform channel behind it.
class ConnectivityWatcher {
  ConnectivityWatcher({TransportProbe? probe})
    : _probe = probe ?? _PluginProbe(),
      _forced = (probe == null && kDebugMode) ? _ForcedProbe(_noSignal) : null;

  final TransportProbe _probe;
  final _ForcedProbe? _forced;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// The current status, and every change to it.
  ///
  /// The first value is the status at the time of subscribing, so a caller
  /// never has to ask separately and race against the first change.
  Stream<ConnectivityStatus> watch() async* {
    yield await current();
    if (_forced != null) {
      yield* _forced._controller.stream.map(_describeStatus);
      return;
    }
    yield* _probe.onConnectivityChanged
        .map(_describe)
        .handleError((Object _) => _noSignal);
  }

  /// The status now.
  Future<ConnectivityStatus> current() async {
    if (_forced != null) {
      return _forced._status;
    }
    try {
      return _describe(await _probe.checkConnectivity());
    } catch (_) {
      // The platform check itself failed (desktop Linux without
      // NetworkManager, a dead plugin channel, a sandboxed device). There is
      // nothing we can honestly call a transport, so report no signal rather
      // than crashing the field app over a radio we cannot see. The push
      // engine already treats every failed request as a deferral, not a loss.
      return _noSignal;
    }
  }

  /// Forces the connectivity status (debug builds only).
  ///
  /// In release builds this is a no-op.
  void forceStatus(ConnectivityStatus status) {
    _forced?.update(status);
  }

  static const ConnectivityStatus _noSignal = ConnectivityStatus(
    hasTransport: false,
    transports: [],
  );

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

  ConnectivityStatus _describeStatus(ConnectivityStatus status) => status;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _forced?.dispose();
  }
}
