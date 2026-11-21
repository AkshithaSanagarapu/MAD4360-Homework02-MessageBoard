import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});
  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final formKey = GlobalKey<FormState>();
  final first = TextEditingController();
  final last = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String role = 'Student';
  bool registering = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final c in [first, last, email, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (registering) {
        await AuthService.instance.register(
          firstName: first.text,
          lastName: last.text,
          role: role,
          email: email.text,
          password: password.text,
        );
      } else {
        await AuthService.instance.signIn(email.text, password.text);
      }
    } catch (e) {
      if (mounted) setState(() => error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Message Board Vault')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.forum_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  registering ? 'Create account' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                if (registering) ...[
                  TextFormField(
                    controller: first,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: last,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const ['Student', 'Instructor', 'Other']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) => setState(() => role = v ?? 'Student'),
                  ),
                ],
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v ?? '').contains('@') ? null : 'Enter a valid email',
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
                ),
                if (registering)
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (v) =>
                        v == password.text ? null : 'Passwords do not match',
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Please wait...'
                        : (registering ? 'Register' : 'Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          registering = !registering;
                          error = null;
                        }),
                  child: Text(
                    registering
                        ? 'Already registered? Sign in'
                        : 'New user? Create account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
