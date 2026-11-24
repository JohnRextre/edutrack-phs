# APPENDICES

## Appendix A â€“ Screenshots of the Application
This section contains the screenshots of the main application screens. *(Insert actual screenshots here during final submission.)*

â€¢ **Figure A.1: Splash Screen / Welcome Homepage** â€“ displays the EduTrack PHS logo and portal entrance.
â€¢ **Figure A.2: User Login Screen** â€“ authentication form supporting email, School ID, and password.
â€¢ **Figure A.3: User Registration Screen** â€“ account creation form with role selection and school details.
â€¢ **Figure A.4: Email Verification Screen** â€“ confirmation screen for email validation.
â€¢ **Figure A.5: Borrower Dashboard Screen** â€“ home screen for students and teachers showing active borrowings and search.
â€¢ **Figure A.6: Learning Resources Catalog Screen** â€“ browsing screen showing categories, search bar, and available quantities.
â€¢ **Figure A.7: QR Camera Scanner Screen** â€“ live camera scanner for item barcodes and QR codes.
â€¢ **Figure A.8: My Borrowings Screen** â€“ list of currently borrowed items with due dates and return buttons.
â€¢ **Figure A.9: Return Submission with Photo Proof Screen** â€“ camera capture screen for attaching proof of item condition.
â€¢ **Figure A.10: Property Custodian Dashboard Screen** â€“ custodian portal for stock overview and pending returns.
â€¢ **Figure A.11: Custodian Return Verification Screen** â€“ screen for inspecting return photos and selecting item condition.
â€¢ **Figure A.12: Administrator Section Management Screen** â€“ screen for configuring sections and borrowing limits.
â€¢ **Figure A.13: Reports and System Audit Logs Screen** â€“ administrative reports and activity history screen.

---

## Appendix B â€“ Source Code Snippets
Selected key source code snippets from the application development are provided below. *(Insert actual code snippets during final submission.)*

### 1. User Authentication and Role-Based Redirection
```dart
// Code snippet from lib/screens/login_screen.dart
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  try {
    final user = await _authService.signInWithAccount(
      email: _identifierController.text.trim(),
      password: _passwordController.text,
      selectedRole: _selectedRole,
    );

    if (!user.emailVerified) {
      Navigator.pushReplacementNamed(context, '/verify-email');
      return;
    }

    // Redirect user to the role-specific dashboard
    Navigator.pushReplacementNamed(
      context,
      '/dashboard',
      arguments: _selectedRole.name,
    );
  } on FirebaseAuthException catch (error) {
    _setLoginError(error);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### 2. Camera QR Code Detection for Borrowing
```dart
// Code snippet from lib/widgets/qr_camera_scanner_screen.dart
void _handleDetection(BarcodeCapture capture) {
  if (_hasReturnedResult) return;

  final rawValue = capture.barcodes.firstOrNull?.rawValue;
  if (rawValue == null || rawValue.trim().isEmpty) return;

  // Validate if scanned QR code belongs to EduTrack PHS inventory
  if (!QrService.isEduTrackPayload(rawValue)) {
    _showErrorMessage('Scanned code is not a valid EduTrack PHS QR code.');
    return;
  }

  _hasReturnedResult = true;
  // Return scanned item code to caller screen
  Navigator.of(context).pop(rawValue);
}
```

### 3. Return Verification and Condition Assessment
```dart
// Code snippet from lib/models/borrow_transaction_model.dart
abstract final class ReturnType {
  static const String goodCondition = 'good_condition';
  static const String paymentProof = 'payment_proof';
  static const String repairedProof = 'repaired_proof';
  static const String replacementProof = 'replacement_proof';

  static const List<String> correctiveOptions = [
    'Payment',
    'Repaired',
    'Replacement Return',
  ];
}
```

---

## Appendix C â€“ User Manual
Follow these steps to use the **EduTrack PHS** Mobile Application:

1. **Install the Application Package (APK)**
   Download and install the `edutrack_phs.apk` package on your Android device. If prompted by your device security settings, enable installation from unknown sources.

2. **Open the Application**
   Tap the EduTrack PHS application icon on your home screen or app drawer to launch the splash screen and welcome page.

3. **Register / Login**
   â€¢ New users must click "Register" and fill out their School ID, full name, email, and designated role.
   â€¢ Complete email verification, then sign in with your registered email/School ID and password. The system will automatically direct you to your assigned role dashboard.

4. **Borrow Learning Resources (Students & Teachers)**
   â€¢ From the dashboard, browse available textbooks, science kits, ICT devices, or TVL tools.
   â€¢ Tap the QR scanner icon to scan the physical QR tag attached to the item.
   â€¢ Review item availability and section limits, then submit your borrow request.

5. **Return Items with Photo Proof**
   â€¢ Open the "My Borrowings" tab to check active items and upcoming due dates.
   â€¢ Tap "Return Item" and use your camera to capture a clear photo of the item showing its condition.
   â€¢ Submit the return for Property Custodian verification.

6. **Inspect Returns and Manage Inventory (Property Custodians)**
   â€¢ Navigate to the Custodian Dashboard to view real-time stock levels and pending return requests.
   â€¢ Inspect uploaded return photos and classify the condition as *Good Condition*, or flag for *Payment, Repair, or Replacement*.

7. **Manage Sections and System Monitoring (Administrators)**
   â€¢ Create school grade levels and sections, assign teachers, and set section borrowing limits to prevent resource hoarding.
   â€¢ Access reports and system logs to audit school-wide borrowing activity.

8. **Logout After Use**
   Always log out of the application after completing your transactions to keep your account and records secure.
