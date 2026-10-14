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

/// A probe that can force a specific connectivity status, for dev/debug use.
///
/// Unforced — a null [update] — it is a pass-through: the real probe answers,
/// and that is the state a debug build starts in. Forcing exists so the
/// offline and online paths can be exercised on demand, never as a default:
/// a debug boot that reports no signal it never measured is the bug that left
/// the desktop map permanently without a basemap.
class _ForcedProbe implements TransportProbe {
  _ForcedProbe(this._probe) {
    // Real changes keep flowing through while the override is cleared.
    _forward = _probe.onConnectivityChanged.listen((results) {
      if (_forced == null) _controller.add(results);
    });
  }

  final TransportProbe _probe;
  ConnectivityStatus? _forced;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _forward;

  /// The override in force, or null when the real probe is being followed.
  ConnectivityStatus? get forcedStatus => _forced;

  void update(ConnectivityStatus? status) {
    _forced = status;
    if (status != null) {
      _controller.add(_toResults(status));
      return;
    }
    // Clearing the override asks the real probe once more, so the switch back
    // is immediate rather than waiting for the next genuine change.
    _probe
        .checkConnectivity()
        .then(_controller.add)
        .onError<List<ConnectivityResult>>((_, _) => const []);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    final status = _forced;
    if (status != null) return _toResults(status);
    return _probe.checkConnectivity();
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  List<ConnectivityResult> _toResults(ConnectivityStatus status) {
    if (!status.hasTransport) {
      return const [ConnectivityResult.none];
    }
    return const [ConnectivityResult.wifi];
  }

  Future<void> dispose() async {
    await _forward.cancel();
    await _controller.close();
  }
}

/// Watches connectivity and reports it as a stream.
///
/// Injected rather than constructed so a screen or the app root can be built
/// and tested with a known status and no platform channel behind it.
class ConnectivityWatcher {
  ConnectivityWatcher({TransportProbe? probe})
    : this._(
        probe ?? _PluginProbe(),
        // The override exists for debug builds so the offline and online
        // paths can be exercised on demand — never as a default answer:
        // forcing no-signal up front is what used to leave the desktop map
        // permanently without a basemap.
        allowForcing: kDebugMode,
      );

  ConnectivityWatcher._(this._probe, {required bool allowForcing}) {
    _forced = allowForcing ? _ForcedProbe(_probe) : null;
  }

  final TransportProbe _probe;
  _ForcedProbe? _forced;

  /// The current status, and every change to it.
  ///
  /// The first value is the status at the time of subscribing, so a caller
  /// never has to ask separately and race against the first change.
  Stream<ConnectivityStatus> watch() async* {
    yield await current();
    final source =
        _forced?.onConnectivityChanged ?? _probe.onConnectivityChanged;
    yield* source
        .map(_resolveResults)
        .handleError((Object _) => _unknownTransport);
  }

  /// The status now.
  Future<ConnectivityStatus> current() async {
    final forced = _forced?.forcedStatus;
    if (forced != null) {
      return forced;
    }
    try {
      final results = await (_forced ?? _probe).checkConnectivity();
      return _resolveResults(results);
    } catch (_) {
      // The platform check itself failed (a dead plugin channel, a sandboxed
      // device). Nothing here can honestly call a transport: on a phone that
      // means no signal, on a desktop it means the plugin cannot see the
      // network it is in fact attached to (see [_unknownTransport]).
      return _unknownTransport;
    }
  }

  /// Forces the connectivity status, or clears the override with null.
  ///
  /// Debug builds only; in release builds this is a no-op.
  void forceStatus(ConnectivityStatus? status) {
    _forced?.update(status);
  }

  /// The status a measured result means.
  ConnectivityStatus _resolveResults(List<ConnectivityResult> results) {
    final forced = _forced?.forcedStatus;
    if (forced != null) {
      return forced;
    }
    final status = _describe(results);
    if (status.hasTransport) {
      return status;
    }
    // No transport was observed. That is evidence on a phone and a lie on a
    // desktop: connectivity_plus on Linux needs a NetworkManager DBus, and
    // without one it reports no transport on a machine whose network works
    // — the same lie `reference_loader.dart` documents. Transport on a
    // desktop is proven per request (a fetch succeeds or fails), and every
    // caller here already treats a failed request as a deferral, so assume a
    // transport rather than withholding the network from the map and sync.
    if (_isDesktop) {
      return _desktopTransport;
    }
    return status;
  }

  /// What to report when the platform cannot answer at all.
  ConnectivityStatus get _unknownTransport =>
      _isDesktop ? _desktopTransport : _noSignal;

  /// Desktop connectivity plugins answer for a radio that does not exist, so
  /// their silence is not the absence of a network.
  static bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.macOS => true,
    _ => false,
  };

  static const ConnectivityStatus _desktopTransport = ConnectivityStatus(
    hasTransport: true,
    transports: ['desktop (assumed)'],
  );

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

  Future<void> dispose() async {
    await _forced?.dispose();
  }
}
