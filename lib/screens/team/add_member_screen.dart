import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/database.dart';
import '../../logic/validators.dart';
import '../../models/member.dart';
import '../../widgets/form_bits.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _saving = false;
  bool _emailTaken = false; // set after the database check
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    for (final c in [_name, _role, _email, _pin, _confirmPin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    // Format rules run instantly; "is this email already used" needs
    // the database, so it runs here and re-validates with the result.
    _emailTaken = await AppDatabase.instance.emailExists(_email.text);
    if (!mounted) return;
    if (_emailTaken) {
      setState(() => _saving = false);
      _formKey.currentState!.validate();
      return;
    }

    try {
      await AppDatabase.instance.insertMember(Member(
        name: _name.text.trim(),
        role: _role.text.trim(),
        email: _email.text.trim().toLowerCase(),
        pin: _pin.text,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Adding member failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the member. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add member')),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: fieldDecoration('Full name', Icons.badge_outlined),
              validator: Validators.personName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: fieldDecoration('Role', Icons.work_outline_rounded, hint: 'e.g. QA Tester'),
              validator: Validators.role,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: fieldDecoration('Email', Icons.alternate_email_rounded),
              onChanged: (_) => _emailTaken = false,
              validator: (v) => Validators.email(v) ?? (_emailTaken ? 'This email is already on the team' : null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: fieldDecoration('4 digit PIN', Icons.lock_outline_rounded),
              validator: Validators.pin,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: fieldDecoration('Confirm PIN', Icons.lock_reset_rounded),
              validator: (v) => v != _pin.text ? 'PINs do not match' : null,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add to team'),
            ),
          ],
        ),
      ),
    );
  }
}
