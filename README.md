# Homework 02 – Message Board Vault Hunt (Graduate)

Student Name: Akshitha Sainath Sanagarapu  
Student ID: 003027780  
Course: MAD 4360 – Mobile App Development

## Project
I built a Flutter message board with Firebase Authentication, a five-field Firestore user profile, and real-time message CRUD. Firebase initializes through a splash screen with a retry option. `authStateChanges()` routes signed-out users to the authentication screen and signed-in users to the board after their profile loads.

## Data and security
`users/{uid}` stores `uid`, `firstName`, `lastName`, `role`, and `registrationDateTime`. `messages/{id}` stores `text`, `authorUid`, `authorName`, `createdAt`, `editedAt`, and `schemaVersion`. `firestore.rules` restricts profile reads to the owner, denies profile listing and changes, requires authentication for message reads, and limits message writes to the author with field validation. UI-only edit/delete hiding is not treated as authorization.

## Implemented features
- Firebase initialization splash with retry
- Email/password registration, sign-in, sign-out, profile recovery
- Live board powered by Firestore `snapshots()`
- Create, edit, delete messages with owner-only actions
- Stable operation ID reused for a pending post retry
- Firebase emulator setup, five Firestore rules unit tests
- Emulator-only sample migration from schema v1 to v2

## Setup and testing
1. Install Flutter and Android SDK; run `flutter pub get`.
2. Configure a Firebase project for this app and enable Email/Password Authentication and Cloud Firestore. The project includes FlutterFire configuration; use your own Firebase configuration if cloning into another project.
3. Review and deploy `firestore.rules` to the Firebase project before testing real accounts. Never commit service-account keys, passwords, or tokens.
4. Run `flutter run` on an Android emulator.
5. Run `flutter analyze` and `flutter test`.
6. To run emulator security tests, install Node dependencies with `npm ci`, start Firebase Auth and Firestore emulators (`firebase emulators:start --only auth,firestore`), then run `node --test tests/firestore.rules.test.cjs`. Warning: the rules test setup clears the local Firestore emulator database.
7. For the sample migration, run `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/migrate_v1_to_v2.cjs` while the Firestore emulator is running. This script intentionally uses the emulator and operates on three sample records.
8. Build with `flutter build apk --release`. Install the exact APK using `adb install -r build/app/outputs/flutter-apk/app-release.apk`.

## Verification
On November 21, 2026, Flutter analysis reported no issues, Flutter tests passed, the 52.1 MB release APK built and installed successfully on Android emulator-5554, and release login/CRUD were manually checked. Cross-session live updates were also checked. The saved rules-unit-test output shows five passes, including signed-out denial, cross-user edit denial, forged author rejection, owner CRUD, and duplicate-operation-ID rejection. The sample migration verified three records and preserved their original fields.

## Evidence and limitations
See `evidence/` for Firebase emulator screenshots and migration JSON, `security_test_results.txt` for rule tests, and the accompanying graduate report for architecture, AI critique, case files, and reflection. The migration is a sample exercise, not a production migration. A repeated operation ID avoids duplicate documents but can surface a permission error on an ambiguous retry. The live board is not yet paginated.

## Repository
https://github.com/AkshithaSanagarapu/MAD4360-Homework02-MessageBoard
