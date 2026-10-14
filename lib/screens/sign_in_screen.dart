import 'package:field_log/design/components.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/net/server_address.dart';
import 'package:flutter/material.dart';

/// Signing in, and being told plainly what happened when it does not.
///
/// The design brief is a notebook that works in a vehicle. That has two
/// consequences here. The screen is short, because a form that scrolls is a
/// form that cannot be finished one-handed. And the failure message says what
/// to do next rather than what the service returned, because "UNAUTHORIZED" on
/// a phone at a waterhole is a shrug.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignIn,
    required this.initialServer,
    this.onSaveServer,
  });

  /// Completes with the credentials. The caller stores them and then reads the
  /// user from the service, rather than this screen holding a session it would
  /// have to keep alive.
  final Future<void> Function(String username, String password) onSignIn;

  /// The server the client is currently pointed at, shown in the address
  /// field so the operator can see where the credentials are going.
  final String initialServer;

  /// Applied (and remembered) before [onSignIn] when the address was edited.
  /// Without this the field would be decoration: the request would still go
  /// to the old server.
  final Future<void> Function(String server)? onSaveServer;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final TextEditingController _server;
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _busy = false;
  bool _showPassword = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.initialServer);
  }

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final username = _username.text.trim();
    final password = _password.text;

    // Shared with settings: the same typing rules wherever the address is
    // edited, so one field cannot accept what the other refuses.
    final server = normaliseServerAddress(_server.text);
    if (server == null) {
      setState(() => _problem = 'Enter the address of the reserve office.');
      return;
    }

    setState(() {
      _busy = true;
      _problem = null;
    });

    try {
      // Before the sign-in: the request must go to the server just named,
      // not the one the app started with.
      if (server != widget.initialServer) {
        await widget.onSaveServer?.call(server);
      }
      await widget.onSignIn(username, password);
      // Clear the password before the route goes: if it survived in memory
      // it would outlive the form that typed it.
      _password.clear();
      // The screen closes itself on success. Nothing downstream can show a
      // signed-in map while this route still covers it, and the caller has
      // no reason to know this route exists beyond handing over its callback.
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _problem = failure.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _problem = 'Could not sign in. $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;

    return FieldScaffold(
      title: 'Field LogBook',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.md,
            Insets.xl,
            Insets.giant,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in to send your records to the reserve office.',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.supporting,
                    height: 1.4,
                    color: colours.ash2,
                  ),
                ),
                const SizedBox(height: Insets.xxl),
                FieldFormField(
                  controller: _server,
                  label: 'Reserve office address',
                  hint: 'http://reserve.example:8080',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _usernameFocus.requestFocus(),
                  autofillHints: const [AutofillHints.url],
                ),
                const SizedBox(height: Insets.lg),
                FieldFormField(
                  controller: _username,
                  label: 'Username',
                  focusNode: _usernameFocus,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: Insets.lg),
                FieldFormField(
                  controller: _password,
                  label: 'Password',
                  focusNode: _passwordFocus,
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colours.ash2,
                    ),
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                  ),
                ),
                if (_problem != null) ...[
                  const SizedBox(height: Insets.lg),
                  FieldBanner(
                    message: _problem!,
                    type: FieldSnackBarType.error,
                    onDismiss: () => setState(() => _problem = null),
                  ),
                ],
                const SizedBox(height: Insets.xl),
                FieldPrimaryButton(
                  label: 'Sign in',
                  onPressed: _busy ? null : _submit,
                  isLoading: _busy,
                ),
                const SizedBox(height: Insets.lg),
                Text(
                  'You can record without signing in. Records stay on this '
                  'phone and go when you sign in later.',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    height: 1.4,
                    color: colours.ash3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
