# EduTrack PHS

EduTrack PHS is a high school resource inventory and borrowing system. It
helps schools track equipment and books, manage borrow requests, and verify
returns with photo proof.

## Features

- Browse textbooks, ICT devices, science kits, and TVL tools.
- Check current resource availability and stock counts.
- Search resources by item name or resource code.
- Filter resources by category and availability.
- Sort resources by name, popularity, or date added.
- Switch between grid view and list view.
- Submit and track borrowing requests.
- View due dates and active borrowings.
- Upload photo proof when returning an item.
- View account activities and transaction history.
- Edit profile information such as name, section or department, and phone.
- Sign in using a School ID or email address.

## User Roles

### Students and Teachers

Students and teachers can search resources, submit borrow requests, track due
dates, and upload return photos.

### Property Custodians

Property Custodians can approve borrow requests, inspect return photo proof,
manage inventory, and update stock counts.

### ICT Coordinators and Admins

ICT Coordinators and admins can manage user accounts, assign roles, review
activity logs, and monitor the system.

## Technology

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Material 3

## Project Structure

```text
lib/
	models/       Data models for users, resources, and transactions
	screens/      Application screens and role-based workflows
	services/     Firebase and business logic services
	widgets/      Shared UI components
	main.dart     Application entry point and route configuration
test/           Unit and widget tests
```

## Setup

### Requirements

- Flutter SDK
- Dart SDK included with Flutter
- A Firebase project
- Android Studio or Xcode for mobile development

### Install Dependencies

```bash
flutter pub get
```

### Firebase Configuration

Configure Firebase for the target platforms before running the app:

- Android: add the correct `google-services.json` in `android/app/`.
- iOS: add `GoogleService-Info.plist` to the Runner target.
- Web: provide the Firebase web configuration in `firebase_options.dart`.

The app initializes Firebase in `lib/main.dart` through
`AuthService.initialize()`.

### Run the App

```bash
flutter run
```

To see available devices:

```bash
flutter devices
```

## Test and Analyze

```bash
flutter analyze
flutter test
```

## Firestore Collections

The application currently uses these main collections:

- `users` for account profiles, roles, approval status, and contact details.
- `resources` for school equipment and book inventory.
- `borrow_transactions` for requests, borrowings, returns, and rejection data.

Firestore security rules should restrict users to the records and operations
allowed by their role.
