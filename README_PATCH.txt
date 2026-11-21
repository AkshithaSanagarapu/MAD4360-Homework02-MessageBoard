HOMEWORK 02 CODE PATCH (initial functional app, not final graduate submission)

1. From Terminal in ~/Downloads/MAD4360-Homework02-MessageBoard:
   cp -R lib ~/Downloads/Homework02_Backups/lib_before_patch

2. Unzip this archive into your project root, replacing files when prompted.
   The archive includes complete replacements for main.dart, auth_service.dart,
   authentication_screen.dart, auth_gate.dart, and new board_screen.dart and board_service.dart.
   Existing firebase_options.dart is NOT replaced.

3. Firebase Console > Firestore > Rules: replace all rules with firestore.rules and Publish.
   Do this before registering accounts.

4. Run:
   dart format lib/main.dart lib/services/auth_service.dart lib/services/board_service.dart lib/screens/auth_gate.dart lib/screens/authentication_screen.dart lib/screens/board_screen.dart
   flutter analyze
   flutter run -d emulator-5554

5. Test registration, posting, editing, deletion, and sign out.

NOT COMPLETE YET: graduate 4 spices, emulator rules unit tests, schema migration,
release APK gate, screenshots, evidence report, and AI review. Do not submit yet.
