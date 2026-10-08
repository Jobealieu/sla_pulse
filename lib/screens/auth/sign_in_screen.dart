import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../data/session.dart';
import '../../logic/validators.dart';
import '../../models/member.dart';
import '../../theme.dart';
import '../../widgets/form_bits.dart';
import '../../widgets/member_avatar.dart';

/// Pick your profile, then confirm with a PIN.
/// No real authentication service, as the brief allows.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  List<Member> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.members().then((m) {
      if (!mounted) return;
      setState(() {
        _members = m;
        _loading = false;
      });
    });
  }

  Future<void> _choose(Member m) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true, // lets the sheet move up with the keyboard
      showDragHandle: true,
      builder: (_) => _PinSheet(member: m),
    );
    if (ok != true || !mounted) return;
    await Session.signIn(m);
    if (!mounted) return;
    // Remove the sign in screen from the stack so Back cannot return to it.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                children: [
                  const _Logo(),
                  const SizedBox(height: 20),
                  Text('SLA Pulse', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('See what is slipping before it slips.', style: muted),
                  const SizedBox(height: 36),
                  Text("Who's working today?", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final m in _members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProfileTile(member: m, onTap: () => _choose(m)),
                    ),
                  const SizedBox(height: 8),
                  Text('Demo PIN for every member: 1234', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [brand, Color(0xFF0E9384)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 34),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.member, required this.onTap});

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: MemberAvatar(member, size: 44),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(member.role),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

/// Bottom sheet with one PIN field. Pops true when the PIN is right.
class _PinSheet extends StatefulWidget {
  const _PinSheet({required this.member});

  final Member member;

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  int _wrongTries = 0;
  bool _showPin = false; // false = PIN hidden as dots 

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, true);
    } else if (Validators.pin(_pin.text) == null) {
      // Format was fine, so the PIN itself was wrong.
      setState(() => _wrongTries++);
      _pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // viewInsets = keyboard height, so the field is never hidden behind it.
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MemberAvatar(widget.member, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi ${widget.member.firstName}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Enter your PIN to continue', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _pin,
              autofocus: true,
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: fieldDecoration('PIN', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  tooltip: _showPin ? 'Hide PIN' : 'Show PIN',
                  icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _showPin = !_showPin),
                ),
              ),
              validator: (v) =>
                  Validators.pin(v) ?? (v != widget.member.pin ? 'Incorrect PIN. Try again.' : null),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_wrongTries >= 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Forgot it? The demo PIN is 1234.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
              ),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
