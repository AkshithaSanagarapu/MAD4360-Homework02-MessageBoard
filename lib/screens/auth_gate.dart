import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'authentication_screen.dart';
import 'board_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: AuthService.instance.authStateChanges,
    builder: (context, auth) {
      if (auth.hasError) {
        return const Scaffold(
          body: Center(child: Text('Authentication error')),
        );
      }
      if (auth.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = auth.data;
      if (user == null) return const AuthenticationScreen();
      return StreamBuilder(
        stream: AuthService.instance.profileStream(user.uid),
        builder: (context, profile) {
          if (profile.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Cannot load profile. Check Firestore rules or connection.',
                    ),
                    TextButton(
                      onPressed: AuthService.instance.signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!profile.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final data = profile.data!.data();
          if (data == null ||
              data['uid'] != user.uid ||
              data['firstName'] is! String ||
              data['lastName'] is! String ||
              data['role'] is! String ||
              data['registrationDateTime'] == null) {
            return const ProfileRecoveryScreen();
          }
          return BoardScreen(
            authorName: '${data['firstName']} ${data['lastName']}',
          );
        },
      );
    },
  );
}

class ProfileRecoveryScreen extends StatefulWidget {
  const ProfileRecoveryScreen({super.key});
  @override
  State<ProfileRecoveryScreen> createState() => _ProfileRecoveryScreenState();
}

class _ProfileRecoveryScreenState extends State<ProfileRecoveryScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  String role = 'Student';
  String? error;
  bool busy = false;
  @override
  void dispose() {
    first.dispose();
    last.dispose();
    super.dispose();
  }

  Future<void> retry() async {
    if (first.text.trim().isEmpty || last.text.trim().isEmpty) {
      setState(() => error = 'Enter both names.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final user = AuthService.instance.currentUser!;
      await AuthService.instance.createProfileIfMissing(
        uid: user.uid,
        firstName: first.text,
        lastName: last.text,
        role: role,
      );
    } catch (e) {
      if (mounted) setState(() => error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Finish your profile')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your account exists, but the profile needs to be saved. Enter your original registration details.',
              ),
              TextField(
                controller: first,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              TextField(
                controller: last,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const ['Student', 'Instructor', 'Other']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => role = v ?? 'Student'),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton(
                onPressed: busy ? null : retry,
                child: const Text('Save profile / Retry'),
              ),
              TextButton(
                onPressed: AuthService.instance.signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
