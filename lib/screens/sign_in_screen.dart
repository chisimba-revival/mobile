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
    final colours = context.reserve;

    return FieldScaffold(
      title: 'Field LogBook',
      body: Center(
        child: SingleChildScrollView(
          // The design's bottom safe inset, so the button clears the keyboard
          // rather than hiding behind it.
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.md,
            Insets.xl,
            Insets.giant,
          ),
          child: ConstrainedBox(
            // A long line in a vehicle is a line nobody reads to the end.
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
                _Field(
                  label: 'Reserve office address',
                  controller: _server,
                  colours: colours,
                  hint: 'http://reserve.example:8080',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _usernameFocus.requestFocus(),
                ),
                const SizedBox(height: Insets.lg),
                _Field(
                  label: 'Username',
                  controller: _username,
                  colours: colours,
                  focusNode: _usernameFocus,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: Insets.lg),
                _Field(
                  label: 'Password',
                  controller: _password,
                  colours: colours,
                  obscure: !_showPassword,
                  focusNode: _passwordFocus,
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
                    // An eye is not a label. The screen reader needs to be
                    // told which way the toggle currently points.
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                  ),
                ),
                if (_problem != null) ...[
                  const SizedBox(height: Insets.lg),
                  _Problem(colours: colours, message: _problem!),
                ],
                const SizedBox(height: Insets.xl),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colours.bone,
                      foregroundColor: colours.canopy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Corners.control),
                      ),
                    ),
                    child: _busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colours.canopy,
                            ),
                          )
                        : Text(
                            'Sign in',
                            style: TextStyle(
                              fontFamily: Faces.ui.first,
                              fontSize: Faces.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
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

/// A labelled field. The label sits above the control rather than inside it so
/// the control never has to carry placeholder text that vanishes on focus and
/// takes the label with it.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.colours,
    this.obscure = false,
    this.focusNode,
    this.autofillHints = const <String>[],
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final FieldColours colours;
  final bool obscure;
  final FocusNode? focusNode;
  final List<String> autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  /// Placeholder shown only while the field is empty — an address example,
  /// never a label, for the reason in the class comment above.
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            color: colours.ash2,
          ),
        ),
        const SizedBox(height: Insets.xs),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          autocorrect: false,
          keyboardType: keyboardType,
          // A username is not a sentence and a password is never one.
          enableSuggestions: !obscure,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.body,
            color: colours.bone,
          ),
          cursorColor: colours.bone,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colours.canopyRaised,
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.body,
              color: colours.ash3,
            ),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.rule),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.bone, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.colours, required this.message});

  final FieldColours colours;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colours.blood.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Corners.control),
        border: Border.all(color: colours.blood),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: colours.inkOn(colours.blood),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                height: 1.4,
                color: colours.bone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
