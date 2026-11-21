import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MessageBoardApp());
}

class MessageBoardApp extends StatelessWidget {
  const MessageBoardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Message Board Vault',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const FirebaseSplash(),
  );
}

class FirebaseSplash extends StatefulWidget {
  const FirebaseSplash({super.key});
  @override
  State<FirebaseSplash> createState() => _FirebaseSplashState();
}

class _FirebaseSplashState extends State<FirebaseSplash> {
  late Future<FirebaseApp> initialization;
  @override
  void initState() {
    super.initState();
    retry();
  }

  void retry() {
    setState(() {
      initialization = Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Firebase could not initialize.'),
                Text('${snapshot.error}'),
                FilledButton(onPressed: retry, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum, size: 72),
                SizedBox(height: 16),
                Text('Message Board Vault'),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          ),
        );
      }
      return const AuthGate();
    },
  );
}
