import 'dart:async';

import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/design/components.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/net/connectivity_watcher.dart';
import 'package:field_log/net/server_address.dart';
import 'package:field_log/net/chisimba_api.dart' as chisimba;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    this.currentThemeVariant = ThemeVariant.standard,
    this.onThemeVariantChanged,
    this.currentDensity = Density.comfortable,
    this.onDensityChanged,
    this.currentMapStylePreset = MapStylePreset.field,
    this.onMapStylePresetChanged,
    this.onOpenRouteEditor,
    this.onLoadRoute,
    this.routeOuting,
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

  /// Current theme variant (Standard, High Contrast, Sepia).
  final ThemeVariant currentThemeVariant;

  /// Called when the user selects a new theme variant.
  final void Function(ThemeVariant)? onThemeVariantChanged;

  /// Current density setting.
  final Density currentDensity;

  /// Called when the user selects a new density.
  final void Function(Density)? onDensityChanged;

  /// Current map style preset.
  final MapStylePreset currentMapStylePreset;

  /// Called when the user selects a new map style preset.
  final void Function(MapStylePreset)? onMapStylePresetChanged;

  /// Opens the route editor for the given outing.
  final Future<void> Function(
    chisimba.Outing outing,
    PlannedRoute? existingRoute,
    List<RouteWaypoint> existingWaypoints,
  )?
  onOpenRouteEditor;

  /// Loads the route and waypoints for the given outing.
  final Future<({PlannedRoute? route, List<RouteWaypoint> waypoints})> Function(
    String outingId,
  )?
  onLoadRoute;

  /// The outing whose route the editor would plan. Null when no walk or drive
  /// has been started yet: a route belongs to an outing, so there is nothing
  /// to attach one to until the operator begins one.
  final chisimba.Outing? routeOuting;

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

    // A route belongs to an outing, so there has to be one to plan for. Rather
    // than invent a placeholder outing — which would file the route against an
    // id nothing else knows — say plainly that a walk or drive comes first.
    final outing = widget.routeOuting;
    if (outing == null) {
      if (!mounted) return;
      showFieldSnackBar(
        context: context,
        message: 'Start a drive or walk first, then plan its route.',
        type: FieldSnackBarType.warning,
      );
      return;
    }

    final result = await widget.onLoadRoute!(outing.id);
    if (!mounted) return;

    await widget.onOpenRouteEditor!(outing, result.route, result.waypoints);
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;

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
          FieldSection(
            label: 'Appearance',
            child: widget.onThemeModeChanged == null
                ? Text(
                    'Theme control unavailable.',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.ash3,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Theme mode selector (Canopy/Sunlight/Auto)
                      Wrap(
                        spacing: Insets.sm,
                        runSpacing: Insets.sm,
                        children: [
                          FieldChoiceChip(
                            label: 'Canopy',
                            subtitle: 'Dark',
                            icon: const Icon(Icons.dark_mode),
                            isSelected:
                                widget.currentThemeMode == ThemeMode.dark,
                            onSelected: (_) {},
                            onTap: () {
                              if (widget.currentThemeMode != ThemeMode.dark) {
                                widget.onThemeModeChanged!(ThemeMode.dark);
                              }
                            },
                          ),
                          FieldChoiceChip(
                            label: 'Sunlight',
                            subtitle: 'Light',
                            icon: const Icon(Icons.light_mode),
                            isSelected:
                                widget.currentThemeMode == ThemeMode.light,
                            onSelected: (_) {},
                            onTap: () {
                              if (widget.currentThemeMode != ThemeMode.light) {
                                widget.onThemeModeChanged!(ThemeMode.light);
                              }
                            },
                          ),
                          FieldChoiceChip(
                            label: 'Auto',
                            subtitle: 'System',
                            icon: const Icon(Icons.settings_brightness),
                            isSelected:
                                widget.currentThemeMode == ThemeMode.system,
                            onSelected: (_) {},
                            onTap: () {
                              if (widget.currentThemeMode != ThemeMode.system) {
                                widget.onThemeModeChanged!(ThemeMode.system);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                      // Theme variant selector (Standard/High Contrast/Sepia)
                      Text(
                        'Theme variant',
                        style: TextStyle(
                          fontFamily: Faces.ui.first,
                          fontSize: Faces.label,
                          color: colours.ash2,
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      Wrap(
                        spacing: Insets.sm,
                        runSpacing: Insets.sm,
                        children: [
                          FieldChoiceChip(
                            label: 'Standard',
                            subtitle: 'Default',
                            icon: const Icon(Icons.palette_outlined),
                            isSelected:
                                widget.currentThemeVariant ==
                                ThemeVariant.standard,
                            onSelected: (_) {},
                            onTap: () => widget.onThemeVariantChanged?.call(
                              ThemeVariant.standard,
                            ),
                          ),
                          FieldChoiceChip(
                            label: 'High Contrast',
                            subtitle: 'WCAG AAA',
                            icon: const Icon(Icons.contrast_outlined),
                            isSelected:
                                widget.currentThemeVariant ==
                                ThemeVariant.highContrast,
                            onSelected: (_) {},
                            onTap: () => widget.onThemeVariantChanged?.call(
                              ThemeVariant.highContrast,
                            ),
                          ),
                          FieldChoiceChip(
                            label: 'Sepia',
                            subtitle: 'Warm paper',
                            icon: const Icon(Icons.wb_sunny_outlined),
                            isSelected:
                                widget.currentThemeVariant ==
                                ThemeVariant.sepia,
                            onSelected: (_) {},
                            onTap: () => widget.onThemeVariantChanged?.call(
                              ThemeVariant.sepia,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          FieldSection(
            label: 'Density',
            child: widget.onDensityChanged == null
                ? Text(
                    'Density control unavailable.',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.ash3,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjust spacing and touch target size.',
                        style: TextStyle(
                          fontFamily: Faces.ui.first,
                          fontSize: Faces.supporting,
                          color: colours.ash2,
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      Wrap(
                        spacing: Insets.sm,
                        runSpacing: Insets.sm,
                        children: [
                          FieldChoiceChip(
                            label: 'Compact',
                            subtitle: 'More content',
                            icon: const Icon(Icons.view_compact),
                            isSelected:
                                widget.currentDensity == Density.compact,
                            onSelected: (_) {},
                            onTap: () =>
                                widget.onDensityChanged?.call(Density.compact),
                          ),
                          FieldChoiceChip(
                            label: 'Comfortable',
                            subtitle: 'Default',
                            icon: const Icon(Icons.view_comfy),
                            isSelected:
                                widget.currentDensity == Density.comfortable,
                            onSelected: (_) {},
                            onTap: () => widget.onDensityChanged?.call(
                              Density.comfortable,
                            ),
                          ),
                          FieldChoiceChip(
                            label: 'Spacious',
                            subtitle: 'More breathing room',
                            icon: const Icon(Icons.view_agenda),
                            isSelected:
                                widget.currentDensity == Density.spacious,
                            onSelected: (_) {},
                            onTap: () =>
                                widget.onDensityChanged?.call(Density.spacious),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          FieldSection(
            label: 'Map style',
            child: widget.onMapStylePresetChanged == null
                ? Text(
                    'Map style control unavailable.',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.ash3,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a preset for your field task.',
                        style: TextStyle(
                          fontFamily: Faces.ui.first,
                          fontSize: Faces.supporting,
                          color: colours.ash2,
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      Wrap(
                        spacing: Insets.sm,
                        runSpacing: Insets.sm,
                        children: [
                          FieldChoiceChip(
                            label: 'Field',
                            subtitle: 'Observations, species, accuracy',
                            icon: const Icon(Icons.pets_outlined),
                            isSelected:
                                widget.currentMapStylePreset ==
                                MapStylePreset.field,
                            onSelected: (_) {},
                            onTap: () => widget.onMapStylePresetChanged?.call(
                              MapStylePreset.field,
                            ),
                          ),
                          FieldChoiceChip(
                            label: 'Navigation',
                            subtitle: 'Routes, waypoints, bearing',
                            icon: const Icon(Icons.navigation_outlined),
                            isSelected:
                                widget.currentMapStylePreset ==
                                MapStylePreset.navigation,
                            onSelected: (_) {},
                            onTap: () => widget.onMapStylePresetChanged?.call(
                              MapStylePreset.navigation,
                            ),
                          ),
                          FieldChoiceChip(
                            label: 'Survey',
                            subtitle: 'Boundaries, transects, grid',
                            icon: const Icon(Icons.grid_on_outlined),
                            isSelected:
                                widget.currentMapStylePreset ==
                                MapStylePreset.survey,
                            onSelected: (_) {},
                            onTap: () => widget.onMapStylePresetChanged?.call(
                              MapStylePreset.survey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          FieldSection(
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
                      FieldPrimaryButton(
                        label: 'Sign in',
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
                      FieldSecondaryButton(
                        label: 'Sign out',
                        onPressed: widget.onSignOut == null
                            ? null
                            : () => unawaited(_signOut()),
                      ),
                    ],
                  ),
          ),
          FieldSection(
            label: 'Reserve office address',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldFormField(
                  controller: _server,
                  label: 'Reserve office address',
                  hint: 'http://reserve.example:8080',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  errorText: _addressProblem,
                  helperText: _addressSaved,
                ),
                const SizedBox(height: Insets.md),
                FieldSecondaryButton(
                  label: 'Save address',
                  onPressed: widget.onSaveServer == null
                      ? null
                      : () => unawaited(_saveAddress()),
                ),
              ],
            ),
          ),
          FieldSection(
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
                FieldSecondaryButton(
                  label: 'Manage outings & routes',
                  onPressed: widget.onOpenRouteEditor == null
                      ? null
                      : () => unawaited(_openRouteEditor()),
                ),
              ],
            ),
          ),
          FieldSection(
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
                FieldSecondaryButton(
                  label: _referenceBusy ? 'Refreshing…' : 'Refresh',
                  onPressed: widget.onLoadReference == null || _referenceBusy
                      ? null
                      : () => unawaited(_loadReference(forceRefresh: true)),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            FieldSection(
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
                  FieldSegmentedControl<ConnectivityStatus?>(
                    segments: {
                      null: const Text('Auto (real)'),
                      ConnectivityStatus(
                        hasTransport: true,
                        transports: ['wifi (forced)'],
                      ): const Text(
                        'Force Online',
                      ),
                      ConnectivityStatus(hasTransport: false, transports: []):
                          const Text('Force Offline'),
                    },
                    selectedValue: _forcedStatus,
                    onChanged: (status) async {
                      setState(() => _forcedStatus = status);
                      await widget.onForceConnectivity?.call(status);
                    },
                  ),
                ],
              ),
            ),
          ],
          FieldSection(
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
