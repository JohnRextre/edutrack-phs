# EduTrack PHS

EduTrack PHS is a high school resource inventory and borrowing system. It
helps schools track equipment and books, manage role-based borrow workflows,
monitor transactions, and verify returns with photo proof.

## Features

- Browse textbooks, ICT devices, science kits, and TVL tools.
- Check current resource availability and stock counts.
- Search resources by item name or resource code.
- Filter resources by category and availability.
- Sort resources by name, popularity, or date added.
- Switch between grid view and list view.
- Start automated borrowing when an item is available and track the resulting
  transaction.
- View due dates and active borrowings.
- Scan QR codes to borrow or return tagged resources.
- Upload photo proof when returning an item.
- Submit return resolutions or appeals when a transaction needs review.
- View account activities and transaction history.
- Receive role-specific notifications for borrowing, returns, and account
  activity.
- Edit profile information such as name, section or department, and phone.
- Sign in using a School ID or email address.

## User Roles

### Students and Teachers

Students and teachers can search resources, start automated borrowing for
available items, use QR borrow and return flows, track due dates, receive
notifications, and upload return photos. They can also review transaction
details and submit a resolution or appeal when needed.

### Property Custodians

Property Custodians can manage borrowed inventory, inspect and verify return
photo proof, manage resources, update stock counts, and review reports and
analytics.

### ICT Coordinators and Admins

ICT Coordinators and admins can manage user accounts and sections, assign
roles, review activity logs, monitor borrowing transactions and resource
inventory, view reports, and receive system notifications.

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
- A device or emulator with camera support for QR scanning

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
- `borrow_transactions` for automated borrowings, returns, rejection data, and
  return verification details.
- `sections` for class and department section assignments.
- `audit_logs` for system activity and administrative audit records.
- User-scoped `notification_reads` documents for notification read status.

Firestore security rules should restrict users to the records and operations
allowed by their role.
