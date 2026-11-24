# Strict AI Agent Rules

## 1. Secrets & Security (Bawal Mag-leak ng Keys)

- NEVER read, open, print, or modify the `.env` file.
- NEVER hardcode API keys, passwords, tokens, or credentials inside any source code file.
- Always use environment variables with Flutter's `String.fromEnvironment('KEY_NAME')` and `flutter run/build --dart-define-from-file=.env`.
- Do not use `process.env` or `os.getenv` in this Dart/Flutter project.
- When adding a new environment variable, only add the key name with a dummy placeholder value inside `.env.example`.
- Never add real secrets to `.env.example`, source code, tests, logs, documentation, assets, or Git commits.

## 2. File & Database Protection (Bawal Magbura Basta-basta)

- NEVER delete, overwrite, or rename existing project files or folders without asking for explicit permission first.
- NEVER drop, reset, truncate, or delete any database, tables, migrations, or local database files (e.g., `.sqlite`, `.db`, `prisma/migrations`).
- Before running any destructive database command or schema migration, explain what will happen and wait for user approval.

## 3. Git & GitHub Safety (Iwas-Disgrasya sa Push)

- NEVER include `.env` or any secret files in `git add` or `git commit`.
- NEVER run `git push --force`, `git reset --hard`, or overwrite existing commit history.
- Always check `git status` before committing to ensure no sensitive files or local database files are staged.

## Project Rules

- This is a Flutter/Dart application named `edutrack_phs`.
- Use the existing Material 3 design and account-role structure.
- Keep changes focused and consistent with the surrounding widgets, services, and test conventions.
- Do not use JavaScript-style environment APIs or Python-style `os.getenv` calls in Flutter.
- Keep screen files in role-based folders under `lib/screens/`:
  - `admin/`: admin-only screens.
  - `auth/`: login, registration, password recovery, and verification screens.
  - `borrower/`: borrower and learning-resource screens.
  - `common/`: shared navigation, profile, activity, and home screens.
  - `custodian/`: property-custodian screens.
  - `student/`: student-specific borrowing and appeal screens.
  - `teacher/`: teacher-specific screens.
- Use relative imports that match the file's folder depth; update `lib/main.dart` and tests when moving screen files.
- Use `kIsWeb` for platform-specific auth and UI behavior.
- Web supports Admin and Property Custodian roles only.
- Mobile supports Student, Teacher, Property Custodian, and ICT Coordinator roles.

## Secrets and Environment Variables

- `.env` contains local secrets and must never be read, opened, printed, committed, or uploaded.
- `.env.example` is the public template. Use it only to discover required variable names.
- Never write real secret values into Dart source files, comments, tests, logs, documentation, or Git commits.
- Do not add `.env` or files containing secrets to assets.
- Keep `.env` and `.env.*` ignored by Git, except for `.env.example`.
- For Flutter web and build-time configuration, prefer `String.fromEnvironment('VARIABLE_NAME')` with `flutter run/build --dart-define-from-file=.env`.
- Do not use `flutter_dotenv` unless runtime asset loading is an explicit requirement; asset loading would expose a value inside the app bundle.
- Validate required configuration with explicit checks and useful errors; never silently fall back to a real production key.

## Firebase

- Firebase initialization and options must continue to use `firebase_core`.
- Required web variables are listed in `.env.example`:
  - `FIREBASE_WEB_API_KEY`
  - `FIREBASE_WEB_APP_ID`
- Reference names as `String.fromEnvironment('FIREBASE_WEB_API_KEY')` and `String.fromEnvironment('FIREBASE_WEB_APP_ID')`.
- Do not add service-account private keys or admin credentials to this Flutter project.
- Do not add `npm firebase` or JavaScript Firebase SDK files to this Flutter project for initialization.
- Use FlutterFire packages and `firebase.json` with `build/web` only for Firebase Hosting deployment.

## Flutter Conventions

- Use `flutter_lints` and run `dart format` on changed Dart files.
- Prefer existing services for Firebase and Firestore operations instead of duplicating API calls in screens.
- Preserve existing route names, role behavior, and localization conventions.
- Use `const` constructors and widgets where practical.
- Dispose `TextEditingController`, animation, subscription, and other owned resources.
- Avoid unrelated refactors and changes outside the requested behavior.

## Testing

- Run the smallest relevant Flutter test command first.
- Update or add focused tests when behavior changes.
- Do not add real credentials to tests or test fixtures.
