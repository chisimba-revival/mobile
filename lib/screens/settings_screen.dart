import 'dart:async';

import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/net/connectivity_watcher.dart';
import 'package:field_log/net/server_address.dart';
import 'package:field_log/net/chisimba_api.dart' as chisimba;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// What a reference load found: how many species are on the phone, and
/// whether the attempt to reach the office failed.
///
/// A count without the failure would say "no species" for both a phone that
/// never downloaded the list and a phone whose office is unreachable, and
/// those two need opposite advice.
class ReferenceLoadResult {
  const ReferenceLoadResult({required this.speciesCount, this.problem});

  final int speciesCount;
  final String? problem;
}

/// The menu the app did not have: account, server address, reference data
/// and the app's own name, on one pushed screen.
///
/// Everything here is callback-driven — the screen never touches the
/// navigator to leave (the scaffold's back arrow does that), never owns the
/// session and never writes preferences itself. It states what it was given
/// and reports what was asked for, which is what lets it be built and tested
/// with none of the machinery behind a real phone.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initialServer,
    this.signedInAs,
    this.onSignIn,
    this.onSignOut,
    this.onSaveServer,
    this.onLoadReference,
    this.onForceConnectivity,
    this.currentThemeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.onOpenRouteEditor,
    this.onLoadRoute,
  });

  /// The server the client is currently pointed at, shown in the address
  /// field so the operator can see where their credentials go.
  final String initialServer;

  /// The person holding the phone, or null when nobody is signed in.
  final String? signedInAs;

  /// Opens sign-in and completes with the name now signed in, or null when
  /// the operator backed out without signing in. Returning the name (rather
  /// than the screen subscribing to anything) keeps the account section's
  /// state honest: it shows exactly what the callback reports.
  final Future<String?> Function()? onSignIn;

  final Future<void> Function()? onSignOut;

  /// Applied (and remembered) when the address was edited.
  final Future<void> Function(String server)? onSaveServer;

  /// Cache-first load on open; the Refresh button calls it again with
  /// forceRefresh. Completes with the species count on the phone and any
  /// refresh problem.
  final Future<ReferenceLoadResult> Function({required bool forceRefresh})?
  onLoadReference;

  /// Debug-only: called when the user toggles the forced connectivity status.
  /// Receives the new forced status (null to clear and use real connectivity).
  final Future<void> Function(ConnectivityStatus? status)? onForceConnectivity;

  /// Current theme mode, displayed in the Appearance section.
  final ThemeMode currentThemeMode;

  /// Called when the user selects a new theme mode.
  final void Function(ThemeMode)? onThemeModeChanged;

  /// Opens the route editor for the given outing.
  final Future<void> Function(
    chisimba.Outing outing,
    PlannedRoute? existingRoute,
    List<RouteWaypoint> existingWaypoints,
  )?
  onOpenRouteEditor;

  /// Loads the route and waypoints for the given outing.
  final Future<({PlannedRoute? route, List<RouteWaypoint> waypoints})>
  Function()?
  onLoadRoute;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _server;

  String? _signedInAs;
  String? _addressProblem;
  String? _addressSaved;

  bool _referenceBusy = false;
  int? _speciesCount;
  String? _referenceProblem;

  // Dev-only: force connectivity status
  ConnectivityStatus? _forcedStatus;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.initialServer);
    _signedInAs = widget.signedInAs;
    _loadReference(forceRefresh: false);
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _loadReference({required bool forceRefresh}) async {
    final load = widget.onLoadReference;
    if (load == null || _referenceBusy) {
      return;
    }
    setState(() => _referenceBusy = true);
    final result = await load(forceRefresh: forceRefresh);
    if (!mounted) {
      return;
    }
    setState(() {
      _speciesCount = result.speciesCount;
      _referenceProblem = result.problem;
      _referenceBusy = false;
    });
  }

  Future<void> _saveAddress() async {
    final server = normaliseServerAddress(_server.text);
    if (server == null) {
      setState(() {
        _addressProblem = 'Enter the address of the reserve office.';
        _addressSaved = null;
      });
      return;
    }
    setState(() {
      _addressProblem = null;
      _addressSaved = null;
    });
    await widget.onSaveServer?.call(server);
    if (!mounted) {
      return;
    }
    setState(() => _addressSaved = 'Saved. New requests go to $server.');
  }

  Future<void> _signIn() async {
    final name = await widget.onSignIn?.call();
    if (!mounted || name == null) {
      return;
    }
    setState(() => _signedInAs = name);
  }

  Future<void> _signOut() async {
    // Sign-out stops the sync that is currently working, so it is asked for
    // rather than taken. The only worse outcome than a dialog here is a
    // trainee discovering their session ended because they meant to tap
    // "settings" and hit their own name instead.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colours = dialogContext.reserve;
        return AlertDialog(
          backgroundColor: colours.canopyRaised,
          title: Text(
            'Sign out?',
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.cardTitle,
              color: colours.bone,
            ),
          ),
          content: Text(
            'Sending pauses until someone signs in again. Records already '
            'on this phone are not affected.',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              height: 1.4,
              color: colours.ash2,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Stay signed in',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.label,
                  color: colours.ash1,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Sign out',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.label,
                  fontWeight: FontWeight.w600,
                  color: colours.bone,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await widget.onSignOut?.call();
    if (!mounted) {
      return;
    }
    setState(() => _signedInAs = null);
  }

  Future<void> _openRouteEditor() async {
    if (widget.onOpenRouteEditor == null || widget.onLoadRoute == null) {
      return;
    }

    // For now, we'll open the route editor for the first available outing.
    // A full implementation would show a list of outings to choose from.
    // This is a simplified version that uses a placeholder outing.
    // In a full implementation, we'd fetch the list of outings from the API
    // and let the user choose which one to plan a route for.
    final placeholderOuting = chisimba.Outing(
      id: 'placeholder',
      kind: 'Trail walk',
      contextCode: 'field:write',
      guideId: '',
      traineeIds: const [],
      status: 'planned',
      plannedStart: DateTime.now().toUtc().toIso8601String(),
      endedAt: null,
      sealedAt: null,
      notes: null,
      revision: 0,
    );

    final result = await widget.onLoadRoute!();
    if (!mounted) return;

    await widget.onOpenRouteEditor!(
      placeholderOuting,
      result.route,
      result.waypoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    return FieldScaffold(
      eyebrow: 'Settings',
      title: 'How this phone is set',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.lg,
          Insets.lg,
          Insets.giant,
        ),
        children: [
          _Section(
            label: 'Appearance',
            child: _ThemeSelector(
              currentMode: widget.currentThemeMode,
              onChanged: widget.onThemeModeChanged,
              colours: colours,
            ),
          ),
          const SizedBox(height: Insets.xl),
          _Section(
            label: 'Account',
            child: _signedInAs == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not sending yet. Records are safe on this phone.',
                        style: _body(colours),
                      ),
                      const SizedBox(height: Insets.md),
                      _PrimaryButton(
                        label: 'Sign in',
                        colours: colours,
                        onPressed: widget.onSignIn == null
                            ? null
                            : () => unawaited(_signIn()),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signed in as $_signedInAs.', style: _body(colours)),
                      const SizedBox(height: Insets.md),
                      _OutlinedButton(
                        label: 'Sign out',
                        colours: colours,
                        onPressed: widget.onSignOut == null
                            ? null
                            : () => unawaited(_signOut()),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: Insets.xl),
          _Section(
            label: 'Reserve office address',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _server,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: colours.inset,
                    hintText: 'http://reserve.example:8080',
                    hintStyle: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.body,
                      color: colours.ash3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.rule),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.rule),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.ruleStrong),
                    ),
                  ),
                ),
                if (_addressProblem != null) ...[
                  const SizedBox(height: Insets.sm),
                  Text(
                    _addressProblem!,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.straw,
                    ),
                  ),
                ],
                if (_addressSaved != null) ...[
                  const SizedBox(height: Insets.sm),
                  Text(
                    _addressSaved!,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.moss,
                    ),
                  ),
                ],
                const SizedBox(height: Insets.md),
                _OutlinedButton(
                  label: 'Save address',
                  colours: colours,
                  onPressed: widget.onSaveServer == null
                      ? null
                      : () => unawaited(_saveAddress()),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          _Section(
            label: 'Outings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan routes for your outings. A route lets you see the '
                  'planned path on the map before you start.',
                  style: _body(colours),
                ),
                const SizedBox(height: Insets.md),
                _OutlinedButton(
                  label: 'Manage outings & routes',
                  colours: colours,
                  onPressed: widget.onOpenRouteEditor == null
                      ? null
                      : () => unawaited(_openRouteEditor()),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          _Section(
            label: 'Reference data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _referenceBusy
                      ? 'Checking the species list…'
                      : _speciesCount == null
                      ? 'Species list not checked yet.'
                      : _speciesCount == 0
                      ? 'No species list yet. Connect and refresh to fetch '
                            'it from the reserve office.'
                      : '$_speciesCount species on this phone.',
                  style: _body(colours),
                ),
                if (_referenceProblem != null) ...[
                  const SizedBox(height: Insets.sm),
                  Text(
                    'Could not refresh: $_referenceProblem',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.straw,
                    ),
                  ),
                ],
                const SizedBox(height: Insets.md),
                _OutlinedButton(
                  label: _referenceBusy ? 'Refreshing…' : 'Refresh',
                  colours: colours,
                  onPressed: widget.onLoadReference == null || _referenceBusy
                      ? null
                      : () => unawaited(_loadReference(forceRefresh: true)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          if (kDebugMode) ...[
            _Section(
              label: 'Dev tools',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Force connectivity state (debug only). The app normally '
                    'detects connectivity automatically; this overrides it for '
                    'testing.',
                    style: _body(colours),
                  ),
                  const SizedBox(height: Insets.md),
                  Row(
                    children: [
                      Expanded(
                        child: _OutlinedButton(
                          label: _forcedStatus == null
                              ? 'Auto (real)'
                              : (_forcedStatus!.hasTransport
                                    ? 'Forced: Online'
                                    : 'Forced: Offline'),
                          colours: colours,
                          onPressed: () async {
                            setState(() {
                              _forcedStatus = null;
                            });
                            await widget.onForceConnectivity?.call(null);
                          },
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: _OutlinedButton(
                          label: 'Force Online',
                          colours: colours,
                          onPressed: () async {
                            setState(() {
                              _forcedStatus = ConnectivityStatus(
                                hasTransport: true,
                                transports: ['wifi (forced)'],
                              );
                            });
                            await widget.onForceConnectivity?.call(
                              ConnectivityStatus(
                                hasTransport: true,
                                transports: ['wifi (forced)'],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: _OutlinedButton(
                          label: 'Force Offline',
                          colours: colours,
                          onPressed: () async {
                            setState(() {
                              _forcedStatus = ConnectivityStatus(
                                hasTransport: false,
                                transports: [],
                              );
                            });
                            await widget.onForceConnectivity?.call(
                              ConnectivityStatus(
                                hasTransport: false,
                                transports: [],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.xl),
          ],
          _Section(
            label: 'About',
            child: Text(
              'Field LogBook. Records are stored on this phone and sent to '
              'the reserve office when there is signal.',
              style: _body(colours),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _body(FieldColours colours) => TextStyle(
    fontFamily: Faces.ui.first,
    fontSize: Faces.body,
    height: 1.4,
    color: colours.ash1,
  );
}

/// A labelled card: the label says what the group is, the card holds it, so
/// three unrelated settings do not read as one long form.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            letterSpacing: 0.8,
            color: colours.ash3,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: colours.canopyRaised,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(color: colours.rule),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.colours,
    required this.onPressed,
  });

  final String label;
  final FieldColours colours;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colours.bone,
        foregroundColor: colours.canopy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.label,
    required this.colours,
    required this.onPressed,
  });

  final String label;
  final FieldColours colours;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colours.ash1,
        side: BorderSide(color: colours.rule),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A row of three chips for selecting the app's theme mode.
///
/// The chips are mutually exclusive and show the current selection with a
/// filled background. The labels match the reserve vocabulary: Canopy (dark),
/// Sunlight (light), and Auto (system).
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.currentMode,
    required this.onChanged,
    required this.colours,
  });

  final ThemeMode currentMode;
  final void Function(ThemeMode)? onChanged;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    if (onChanged == null) {
      return Text(
        'Theme control unavailable.',
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.supporting,
          color: colours.ash3,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ThemeChip(
            label: 'Canopy',
            subtitle: 'Dark',
            icon: Icons.dark_mode,
            selected: currentMode == ThemeMode.dark,
            colours: colours,
            onTap: () => onChanged!(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: _ThemeChip(
            label: 'Sunlight',
            subtitle: 'Light',
            icon: Icons.light_mode,
            selected: currentMode == ThemeMode.light,
            colours: colours,
            onTap: () => onChanged!(ThemeMode.light),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: _ThemeChip(
            label: 'Auto',
            subtitle: 'System',
            icon: Icons.settings_brightness,
            selected: currentMode == ThemeMode.system,
            colours: colours,
            onTap: () => onChanged!(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

/// A single theme choice chip.
class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.colours,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final FieldColours colours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '$label theme',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.control),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.lg,
          ),
          decoration: BoxDecoration(
            color: selected ? colours.dust : colours.canopyRaised,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(
              color: selected ? colours.dust : colours.rule,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? colours.bone : colours.ash2,
              ),
              const SizedBox(height: Insets.xs),
              Text(
                label,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.label,
                  fontWeight: FontWeight.w600,
                  color: selected ? colours.bone : colours.bone,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.stamp,
                  color: selected
                      ? colours.bone.withValues(alpha: 0.8)
                      : colours.ash2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
