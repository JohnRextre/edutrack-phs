import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/borrower_navigation_bar.dart';
import 'account_activities_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : FirebaseFirestore.instance
                .collection(AuthService.usersCollection)
                .doc(user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const _ProfileMessage('Please sign in to view your profile.'),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const _ProfileMessage(
              'Unable to load your profile right now.',
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const _ProfileMessage('Profile information not found.'),
          );
        }

        final role = AuthService.roleFromString(_value(data['role']));
        final isBorrower =
            role.toLowerCase() == 'student' || role.toLowerCase() == 'teacher';

        return Scaffold(
          appBar: AppBar(title: Text(isBorrower ? 'Profile' : 'My Account')),
          body: _ProfileContent(
            data: data,
            authUser: user,
            onEditProfile: () => _showEditProfile(context, user, data),
          ),
          bottomNavigationBar: isBorrower
              ? const BorrowerNavigationBar(selectedIndex: 3)
              : null,
        );
      },
    );
  }

  Future<void> _showEditProfile(
    BuildContext context,
    User user,
    Map<String, dynamic> data,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditProfileDialog(
          uid: user.uid,
          data: data,
          userService: _userService,
        ),
      ),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.data,
    required this.authUser,
    required this.onEditProfile,
  });

  final Map<String, dynamic> data;
  final User authUser;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstName = _value(data['firstName']);
    final lastName = _value(data['lastName']);
    final fullName = [
      firstName,
      lastName,
    ].where((name) => name.isNotEmpty).join(' ');
    final displayName = fullName.isEmpty
        ? authUser.displayName ?? 'User'
        : fullName;
    final role = AuthService.roleFromString(_value(data['role']));
    final isStudent = role.toLowerCase() == 'student';
    final isAdmin =
        role.toLowerCase() == 'ict coordinator' ||
        role.toLowerCase() == 'admin';
    final isBorrower =
        role.toLowerCase() == 'student' || role.toLowerCase() == 'teacher';
    final sectionOrDepartment = isStudent
        ? _firstValue(data, ['gradeSection', 'section'])
        : _firstValue(data, ['department', 'departmentOrSection']);
    final identifier = _firstValue(data, ['schoolId', 'idNumber']);
    final email = _firstValue(data, ['email']);
    final isEmailVerified =
        authUser.emailVerified || data['emailVerified'] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Email Verification Banner (only for unverified accounts)
        if (!isEmailVerified) ...[
          _VerifyEmailBanner(authUser: authUser),
          const SizedBox(height: 12),
        ],

        // User Banner
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [colors.primaryContainer, colors.surfaceContainerHighest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _UserAvatarWithBadge(
                  photoUrl:
                      _firstValue(data, [
                        'photoUrl',
                        'photoURL',
                        'avatarUrl',
                      ]).isNotEmpty
                      ? _firstValue(data, ['photoUrl', 'photoURL', 'avatarUrl'])
                      : authUser.photoURL,
                  displayName: displayName,
                  radius: 36,
                  onTap: () => _openPhotoOptions(
                    context,
                    authUser,
                    _firstValue(data, [
                          'photoUrl',
                          'photoURL',
                          'avatarUrl',
                        ]).isNotEmpty
                        ? _firstValue(data, [
                            'photoUrl',
                            'photoURL',
                            'avatarUrl',
                          ])
                        : authUser.photoURL,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(role),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Edit Profile',
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Personal Details Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _DetailTile(
                icon: Icons.badge_outlined,
                title: isStudent
                    ? 'School ID / LRN'
                    : 'Employee ID / School ID',
                value: identifier.isEmpty ? 'Not available' : identifier,
              ),
              const Divider(height: 1),
              _DetailTile(
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: email.isEmpty
                    ? authUser.email ?? 'Not available'
                    : email,
                trailing: _VerificationBadge(isVerified: isEmailVerified),
              ),
              if (isStudent || sectionOrDepartment.isNotEmpty) ...[
                const Divider(height: 1),
                _DetailTile(
                  icon: Icons.school_outlined,
                  title: isStudent ? 'Section' : 'Department',
                  value: sectionOrDepartment.isEmpty
                      ? 'Not available'
                      : sectionOrDepartment,
                ),
              ],
              const Divider(height: 1),
              _DetailTile(
                icon: Icons.phone_outlined,
                title: 'Contact Number',
                value: _firstValue(data, ['phoneNumber']).isEmpty
                    ? 'Not available'
                    : _firstValue(data, ['phoneNumber']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Account Options Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (isBorrower) ...[
                ListTile(
                  leading: Icon(Icons.history, color: colors.primary),
                  title: const Text('Account Activities'),
                  subtitle: const Text(
                    'View borrowing and transaction history',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountActivitiesScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: Icon(Icons.lock_outline, color: colors.primary),
                title: const Text('Password & Security'),
                subtitle: const Text(
                  'Change password and manage account protection',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPasswordSecuritySheet(context),
              ),
            ],
          ),
        ),

        // Delete Account Section (Admin role excluded)
        if (!isAdmin) ...[
          const SizedBox(height: 16),
          _DeleteAccountCard(onDelete: () => _showDeleteAccountDialog(context)),
        ],
        const SizedBox(height: 24),

        // Log out button
        FilledButton.tonalIcon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showPasswordSecuritySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PasswordSecurityModal(authUser: authUser),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteAccountDialog(authUser: authUser, uid: authUser.uid),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openPhotoOptions(
    BuildContext context,
    User authUser,
    String? currentPhoto,
  ) async {
    final picker = ImagePicker();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: colors.primary,
                ),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1200,
                      maxHeight: 1200,
                      imageQuality: 85,
                    );
                    if (picked != null && context.mounted) {
                      final bytes = await picked.readAsBytes();
                      if (context.mounted) {
                        _openCropperAndSave(context, authUser, bytes);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open camera: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: colors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1200,
                      maxHeight: 1200,
                      imageQuality: 85,
                    );
                    if (picked != null && context.mounted) {
                      final bytes = await picked.readAsBytes();
                      if (context.mounted) {
                        _openCropperAndSave(context, authUser, bytes);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open gallery: $e')),
                      );
                    }
                  }
                },
              ),
              if (currentPhoto != null && currentPhoto.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.error,
                  ),
                  title: Text(
                    'Remove Profile Photo',
                    style: TextStyle(color: colors.error),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _removePhoto(context, authUser);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCropperAndSave(
    BuildContext context,
    User authUser,
    Uint8List imageBytes,
  ) async {
    final croppedDataUrl = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ProfilePhotoCropScreen(imageBytes: imageBytes),
      ),
    );

    if (croppedDataUrl != null && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection(AuthService.usersCollection)
            .doc(authUser.uid)
            .set({'photoUrl': croppedDataUrl}, SetOptions(merge: true));

        try {
          await authUser.updatePhotoURL(croppedDataUrl);
        } catch (_) {}

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile photo: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _removePhoto(BuildContext context, User authUser) async {
    try {
      await FirebaseFirestore.instance
          .collection(AuthService.usersCollection)
          .doc(authUser.uid)
          .update({'photoUrl': FieldValue.delete()});

      try {
        await authUser.updatePhotoURL(null);
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Avatar with an edit camera badge supporting Base64, network URL, and initials fallback.
class _UserAvatarWithBadge extends StatelessWidget {
  const _UserAvatarWithBadge({
    required this.photoUrl,
    required this.displayName,
    required this.radius,
    required this.onTap,
  });

  final String? photoUrl;
  final String displayName;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: colors.primary,
              child: _buildAvatarContent(colors),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 13,
                color: colors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(ColorScheme colors) {
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final url = photoUrl!.trim();
      if (url.startsWith('data:image')) {
        try {
          final commaIndex = url.indexOf(',');
          final base64Part = commaIndex != -1
              ? url.substring(commaIndex + 1)
              : url;
          final bytes = base64Decode(base64Part);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitials(colors),
            ),
          );
        } catch (_) {
          return _buildInitials(colors);
        }
      } else if (url.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildInitials(colors),
          ),
        );
      } else {
        return ClipOval(
          child: Image.asset(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildInitials(colors),
          ),
        );
      }
    }
    return _buildInitials(colors);
  }

  Widget _buildInitials(ColorScheme colors) {
    return Text(
      _initials(displayName),
      style: TextStyle(
        color: colors.onPrimary,
        fontSize: radius * 0.65,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Full screen photo cropper, zoom/pan adjuster, and rotator for avatar photos.
class _ProfilePhotoCropScreen extends StatefulWidget {
  const _ProfilePhotoCropScreen({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_ProfilePhotoCropScreen> createState() =>
      _ProfilePhotoCropScreenState();
}

class _ProfilePhotoCropScreenState extends State<_ProfilePhotoCropScreen> {
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _cropAreaKey = GlobalKey();

  int _rotationTurns = 0;
  double _currentScale = 1.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() => _currentScale = scale.clamp(0.5, 4.0));
    }
  }

  void _setScale(double newScale) {
    setState(() => _currentScale = newScale);
    final matrix = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    _transformController.value = matrix;
  }

  void _rotate() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  void _reset() {
    setState(() {
      _rotationTurns = 0;
      _currentScale = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _cropAreaKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture cropped area.');
      }

      final boundaryWidth = boundary.size.width > 0
          ? boundary.size.width
          : 280.0;
      // Target around 200px square for avatars (~30-60KB Base64 string, fits Firestore limit easily)
      final pixelRatio = (200.0 / boundaryWidth).clamp(0.4, 0.85);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image data.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final base64String = base64Encode(pngBytes);
      final dataUrl = 'data:image/png;base64,$base64String';

      if (!mounted) return;
      Navigator.of(context).pop(dataUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cropping image: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: const Text('Edit & Crop Photo', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Reset Adjustment',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
          ),
          TextButton(
            onPressed: _isProcessing ? null : _cropAndSave,
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Pinch to zoom, drag to reposition & adjust focus',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: RepaintBoundary(
                      key: _cropAreaKey,
                      child: Container(
                        color: Colors.black,
                        child: RotatedBox(
                          quarterTurns: _rotationTurns,
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 0.5,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(200),
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls panel
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom Slider
                  Row(
                    children: [
                      const Icon(
                        Icons.zoom_out,
                        color: Colors.white70,
                        size: 20,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF4FC3F7),
                            thumbColor: const Color(0xFF4FC3F7),
                            inactiveTrackColor: Colors.white24,
                          ),
                          child: Slider(
                            value: _currentScale,
                            min: 0.5,
                            max: 4.0,
                            onChanged: (val) => _setScale(val),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.zoom_in,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rotate & Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _rotate,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.rotate_right_rounded),
                        label: const Text('Rotate 90°'),
                      ),
                      FilledButton.icon(
                        onPressed: _isProcessing ? null : _cropAndSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF176B87),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Apply Photo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown in the profile for accounts that haven't verified their email.
class _VerifyEmailBanner extends StatefulWidget {
  const _VerifyEmailBanner({required this.authUser});
  final User authUser;

  @override
  State<_VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends State<_VerifyEmailBanner> {
  bool _isSending = false;
  bool _sent = false;

  Future<void> _sendVerification() async {
    if (_isSending || _sent) return;
    setState(() => _isSending = true);

    try {
      await widget.authUser.sendEmailVerification();
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification email sent to ${widget.authUser.email}. '
            'Please check your inbox and spam folder.',
          ),
          backgroundColor: const Color(0xFF176B87),
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _isChecking = false;

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final isVerified = await AuthService().checkEmailVerified();
      if (!mounted) return;
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your email is now verified!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not yet verified. Please click the link in your email inbox or spam folder first.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_unread_rounded,
            color: Colors.amber.shade800,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email not verified',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _sent
                      ? 'Verification link sent! Check your inbox and spam folder, then tap the link to complete verification.'
                      : 'Your email address has not been verified yet. Tap the button below to send a verification link to ${widget.authUser.email}.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      height: 34,
                      child: FilledButton.icon(
                        onPressed: (_isSending || _sent)
                            ? null
                            : _sendVerification,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _sent
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.send_rounded,
                                size: 16,
                              ),
                        label: Text(
                          _isSending
                              ? 'Sending...'
                              : _sent
                              ? 'Email Sent!'
                              : 'Verify My Account',
                        ),
                      ),
                    ),
                    if (_sent)
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: _isChecking ? null : _checkStatus,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade900,
                            side: BorderSide(color: Colors.amber.shade700),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: _isChecking
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.amber.shade900,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            _isChecking ? 'Checking...' : 'Check Status',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'After clicking the link in your email, come back here to verify your status.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? Colors.green.shade600 : Colors.amber.shade700,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.pending_outlined,
            size: 13,
            color: isVerified ? Colors.green.shade700 : Colors.amber.shade900,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Unverified',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isVerified ? Colors.green.shade800 : Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.onSecondaryContainer),
      ),
      title: Text(title),
      subtitle: Text(value),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// Password & Security Bottom Sheet using system theme colors.
class _PasswordSecurityModal extends StatefulWidget {
  const _PasswordSecurityModal({required this.authUser});

  final User authUser;

  @override
  State<_PasswordSecurityModal> createState() => _PasswordSecurityModalState();
}

class _PasswordSecurityModalState extends State<_PasswordSecurityModal> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChanging = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  ({String label, double fraction, Color color}) _calculateStrength(
    String password,
    ColorScheme colors,
  ) {
    if (password.isEmpty) {
      return (
        label: 'Enter a password',
        fraction: 0.0,
        color: colors.onSurfaceVariant,
      );
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacters = RegExp(
      r'[!@#\$%^&*(),.?":{}|<>]',
    ).hasMatch(password);

    int criteria = 0;
    if (hasUppercase) criteria++;
    if (hasLowercase) criteria++;
    if (hasDigits) criteria++;
    if (hasSpecialCharacters) criteria++;

    if (password.length < 8 || criteria <= 2) {
      return (label: 'Weak', fraction: 0.33, color: colors.error);
    } else if (criteria == 3) {
      return (
        label: 'Medium',
        fraction: 0.66,
        color: Colors.amber[800] ?? Colors.orange,
      );
    } else {
      return (
        label: 'Strong',
        fraction: 1.0,
        color: Colors.green[700] ?? Colors.green,
      );
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (currentPassword.isEmpty) {
      _currentPasswordError = 'Enter current password.';
      hasError = true;
    }

    if (newPassword.isEmpty) {
      _newPasswordError = 'Enter a password.';
      hasError = true;
    } else if (newPassword.length < 8) {
      _newPasswordError = 'Password must be at least 8 characters.';
      hasError = true;
    } else if (currentPassword.isNotEmpty && newPassword == currentPassword) {
      _newPasswordError =
          'New password must be different from current password.';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Confirm your new password.';
      hasError = true;
    } else if (newPassword.isNotEmpty && confirmPassword != newPassword) {
      _confirmPasswordError = 'Passwords do not match.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isChanging = true);

    try {
      final email = widget.authUser.email;
      if (email == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'No email found for this user account.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Re-authenticate with current password
      await widget.authUser.reauthenticateWithCredential(credential);
      // Update with new password
      await widget.authUser.updatePassword(newPassword);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isChanging = false;
        if (error.code == 'wrong-password' ||
            error.code == 'invalid-credential' ||
            error.code == 'invalid-login-credentials') {
          _currentPasswordError = 'Incorrect current password.';
        } else if (error.code == 'weak-password') {
          _newPasswordError = 'Password is too weak.';
        } else {
          _currentPasswordError = AuthService.friendlyErrorMessage(error);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isChanging = false;
        _currentPasswordError = AuthService.friendlyErrorMessage(error);
      });
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  InputDecoration _fieldDecoration(
    String hintText,
    bool isObscured,
    VoidCallback onToggle,
    ColorScheme colors, {
    IconData? prefixIcon,
    Widget? trailingWidget,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13.5,
        color: hasError
            ? colors.error.withValues(alpha: 0.7)
            : colors.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      errorText: errorText,
      errorStyle: TextStyle(
        color: colors.error,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 20,
              color: hasError ? colors.error : colors.onSurfaceVariant,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: hasError
          ? colors.errorContainer.withValues(alpha: 0.08)
          : colors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? colors.error : colors.outlineVariant,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? colors.error : colors.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? colors.error : colors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailingWidget,
          IconButton(
            icon: Icon(
              isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: hasError ? colors.error : colors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final strength = _calculateStrength(newPass, colors);

    final hasMinLength = newPass.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(newPass);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(newPass);
    final hasNumber = RegExp(r'[0-9]').hasMatch(newPass);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPass);

    final passwordsMatch =
        confirmPass.isNotEmpty && newPass.isNotEmpty && confirmPass == newPass;
    final passwordsMismatch =
        confirmPass.isNotEmpty && newPass.isNotEmpty && confirmPass != newPass;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACCOUNT PROTECTION',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Password & Security',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your password regularly to keep your account protected.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'Current Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _currentPasswordError != null
                      ? colors.error
                      : colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                onChanged: (_) {
                  if (_currentPasswordError != null) {
                    setState(() => _currentPasswordError = null);
                  }
                },
                decoration: _fieldDecoration(
                  'Enter current password',
                  _obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent),
                  colors,
                  prefixIcon: Icons.lock_outline_rounded,
                  errorText: _currentPasswordError,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _newPasswordError != null
                      ? colors.error
                      : colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (_) {
                  setState(() {
                    if (_newPasswordError != null) _newPasswordError = null;
                    if (_confirmPasswordController.text.isNotEmpty &&
                        _confirmPasswordError != null &&
                        _confirmPasswordController.text ==
                            _newPasswordController.text) {
                      _confirmPasswordError = null;
                    }
                  });
                },
                decoration: _fieldDecoration(
                  'Enter new password',
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                  colors,
                  prefixIcon: Icons.vpn_key_outlined,
                  errorText: _newPasswordError,
                ),
              ),
              const SizedBox(height: 10),
              if (newPass.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password strength',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      strength.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: strength.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength.fraction,
                    minHeight: 5,
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Requirements checklist card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    _passwordRequirementRow(
                      'At least 8 characters long',
                      hasMinLength,
                      colors,
                    ),
                    const SizedBox(height: 4),
                    _passwordRequirementRow(
                      'At least 1 uppercase letter (A-Z)',
                      hasUppercase,
                      colors,
                    ),
                    const SizedBox(height: 4),
                    _passwordRequirementRow(
                      'At least 1 lowercase letter (a-z)',
                      hasLowercase,
                      colors,
                    ),
                    const SizedBox(height: 4),
                    _passwordRequirementRow(
                      'At least 1 number (0-9)',
                      hasNumber,
                      colors,
                    ),
                    const SizedBox(height: 4),
                    _passwordRequirementRow(
                      'At least 1 special character (!@#\$%^&*)',
                      hasSpecial,
                      colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _confirmPasswordError != null
                      ? colors.error
                      : colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onChanged: (_) {
                  setState(() {
                    if (_confirmPasswordError != null) {
                      if (_confirmPasswordController.text ==
                          _newPasswordController.text) {
                        _confirmPasswordError = null;
                      }
                    }
                  });
                },
                decoration: _fieldDecoration(
                  'Confirm new password',
                  _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                  colors,
                  prefixIcon: Icons.lock_reset_rounded,
                  errorText: _confirmPasswordError,
                  trailingWidget: passwordsMatch
                      ? const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 18,
                          ),
                        )
                      : passwordsMismatch && _confirmPasswordError == null
                      ? const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.cancel_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _isChanging ? null : _handleChangePassword,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isChanging
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordRequirementRow(String text, bool met, ColorScheme colors) {
    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: met
              ? Colors.green
              : colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: met
                  ? colors.onSurface
                  : colors.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Delete Account Card in the profile view using system theme colors.
class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
      ),
      color: colors.errorContainer.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERMANENT ACTION',
              style: TextStyle(
                color: colors.error,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Are you sure you want to delete this account? This action is irreversible.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete Account Confirmation Modal Dialog that handles keyboard insets cleanly without overflowing.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.authUser, required this.uid});

  final User authUser;
  final String uid;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      // 1. Delete Firestore user record
      await FirebaseFirestore.instance
          .collection(AuthService.usersCollection)
          .doc(widget.uid)
          .delete();

      // 2. Delete Firebase Auth account
      try {
        await widget.authUser.delete();
      } catch (_) {
        // If re-authentication is required, auth deletion might fail, but document is removed and user is signed out
      }

      // 3. Sign out and redirect
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canConfirm = _confirmController.text.trim() == 'Delete';

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERMANENT ACTION',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Delete Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are you sure you want to delete this account? This action is irreversible.',
              style: TextStyle(fontSize: 13.5, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              'Confirmation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Type 'Delete' to confirm",
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.error, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: colors.outlineVariant),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: canConfirm && !_isDeleting ? _handleDelete : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: _isDeleting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onError,
                          ),
                        )
                      : const Text(
                          'Delete Account',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    disabledBackgroundColor: colors.error.withValues(
                      alpha: 0.38,
                    ),
                    disabledForegroundColor: colors.onError.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.uid,
    required this.data,
    required this.userService,
  });

  final String uid;
  final Map<String, dynamic> data;
  final UserService userService;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _sectionController;
  late final TextEditingController _phoneController;
  late final bool _isStudent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: _value(widget.data['firstName']),
    );
    _lastNameController = TextEditingController(
      text: _value(widget.data['lastName']),
    );
    final role = AuthService.roleFromString(_value(widget.data['role']));
    _isStudent = role.toLowerCase() == 'student';
    _sectionController = TextEditingController(
      text: _isStudent
          ? _firstValue(widget.data, ['gradeSection', 'section'])
          : _firstValue(widget.data, ['department', 'departmentOrSection']),
    );
    _phoneController = TextEditingController(
      text: _value(widget.data['phoneNumber']),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sectionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.userService.updateUserProfile(widget.uid, {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        _isStudent ? 'gradeSection' : 'department': _sectionController.text,
        'phoneNumber': _phoneController.text,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    InputDecoration decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your personal details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstNameController,
                  decoration: decoration('First Name', Icons.person_outline),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastNameController,
                  decoration: decoration('Last Name', Icons.person_outline),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sectionController,
                  decoration: decoration(
                    _isStudent ? 'Section / Grade' : 'Department',
                    Icons.school_outlined,
                  ),
                  validator: _isStudent ? _required : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: decoration(
                    'Contact Number',
                    Icons.phone_outlined,
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    return RegExp(r'^[+]?[0-9 ()-]{7,20}$').hasMatch(phone)
                        ? null
                        : 'Enter a valid phone number';
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

String _value(dynamic value) => value?.toString().trim() ?? '';

String _firstValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = _value(data[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _initials(String name) {
  final values = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (values.isEmpty) return '?';
  if (values.length == 1) return values.first.substring(0, 1).toUpperCase();
  return '${values.first.substring(0, 1)}${values.last.substring(0, 1)}'
      .toUpperCase();
}
