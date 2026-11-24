import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _rolesKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  void _openLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102A43);
    const teal = Color(0xFF176B87);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Row(
              children: [
                Image.asset(
                  'lib/assets/edutrack_logo/EduTrack_Rectangle_Logo-NoBackground.png',
                  height: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.school_rounded, color: teal),
                ),
              ],
            ),
            actions: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = MediaQuery.sizeOf(context).width < 1100;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        if (!compact) ...[
                          TextButton(
                            onPressed: () => _scrollTo(_featuresKey),
                            child: const Text('Features'),
                          ),
                          TextButton(
                            onPressed: () => _scrollTo(_rolesKey),
                            child: const Text('For your role'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _openLogin,
                          child: Text(compact ? 'Login' : 'Portal Login'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 700 ? 18 : 32,
                24,
                MediaQuery.sizeOf(context).width < 700 ? 18 : 32,
                56,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    children: [
                      _ModernHero(onFeatures: () => _scrollTo(_featuresKey)),
                      SizedBox(height: 64),
                      _StatsStrip(),
                      SizedBox(height: 88),
                      _FeatureSection(key: _featuresKey),
                      SizedBox(height: 88),
                      _RoleSection(key: _rolesKey),
                      SizedBox(height: 72),
                      _FinalCta(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernHero extends StatelessWidget {
  const _ModernHero({required this.onFeatures});
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102A43);
    const teal = Color(0xFF176B87);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final wide = viewportWidth >= 1280;
    final tablet = viewportWidth >= 900 && viewportWidth < 1280;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4F7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 16, color: teal),
              SizedBox(width: 7),
              Text(
                'SMART SCHOOL RESOURCE MANAGEMENT',
                style: TextStyle(
                  color: teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Every resource,\nright where it belongs.',
          style: TextStyle(
            height: 1.02,
            fontSize: wide ? 62 : 40,
            letterSpacing: -2,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          kIsWeb
              ? 'A focused web workspace for administrators and property custodians to manage school resources with clarity.'
              : 'A modern workspace for managing school resources and borrowing activity.',
          style: const TextStyle(
            height: 1.55,
            fontSize: 17,
            color: Color(0xFF627D98),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open workspace'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 17,
                ),
                side: const BorderSide(color: Color(0xFFD7E2EC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onFeatures,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('See features'),
            ),
          ],
        ),
      ],
    );

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(wide ? 28 : 22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/assets/web/campus.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x660F2C46)],
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live inventory',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Track availability and returns',
                          style: TextStyle(
                            color: Color(0xFF627D98),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: teal),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 560),
      padding: EdgeInsets.all(wide ? 44 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(wide ? 32 : 24),
        border: Border.all(color: const Color(0xFFE5EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2C46),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Expanded(flex: 10, child: content),
                const SizedBox(width: 44),
                Expanded(flex: 10, child: SizedBox(height: 472, child: image)),
              ],
            )
          : tablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 10, child: content),
                const SizedBox(width: 24),
                Expanded(flex: 8, child: SizedBox(height: 390, child: image)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 28),
                SizedBox(height: 300, width: double.infinity, child: image),
              ],
            ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Real-time', 'Inventory status'),
      ('QR-based', 'Borrow and return'),
      ('Role-based', 'Secure workspace'),
      ('Photo proof', 'Return verification'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth < 720;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              Container(
                width: width,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EBF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: Color(0xFF627D98),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          eyebrow: 'A CALMER WAY TO OPERATE',
          title: 'Everything your team needs,\norganized in one place.',
          description:
              'Built for everyday school operations, from inventory review to return verification.',
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final side = SizedBox(
              height: wide ? 420 : 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'lib/assets/web/library.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            );
            final cards = Column(
              children: const [
                _FeatureTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Live inventory',
                  body:
                      'Review resources, quantities, and availability without spreadsheets.',
                  accent: Color(0xFFEAF4F7),
                  iconColor: Color(0xFF176B87),
                ),
                SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Fast QR workflow',
                  body:
                      'Scan, inspect, borrow, and return with clear transaction records.',
                  accent: Color(0xFFF4EFE8),
                  iconColor: Color(0xFFA66B27),
                ),
                SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.add_a_photo_outlined,
                  title: 'Photo return verification',
                  body:
                      'Document item condition before custodians approve a return.',
                  accent: Color(0xFFF0EDF7),
                  iconColor: Color(0xFF6C63A5),
                ),
              ],
            );

            if (!wide) {
              return Column(
                children: [side, const SizedBox(height: 16), cards],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: side),
                const SizedBox(width: 16),
                Expanded(flex: 9, child: cards),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          eyebrow,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF176B87),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            height: 1.12,
            color: const Color(0xFF102A43),
            fontSize: wide ? 44 : 34,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          description,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            height: 1.5,
            color: Color(0xFF627D98),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.45,
                    fontSize: 13,
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

class _RoleSection extends StatelessWidget {
  const _RoleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeading(
          eyebrow: 'DESIGNED AROUND PEOPLE',
          title: 'One system. Clear responsibilities.',
          description:
              'Each role gets the tools it needs, from mobile borrowing to web administration.',
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 1100
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: const _RoleCard(
                    icon: Icons.manage_accounts_rounded,
                    label: 'ICT Coordinators',
                    title: 'Admin workspace',
                    body:
                        'Manage accounts, sections, limits, reports, and system activity.',
                    webOnly: true,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _RoleCard(
                    icon: Icons.inventory_rounded,
                    label: 'Property Custodians',
                    title: 'Operations workspace',
                    body:
                        'Review borrowed items, approve returns, and keep stock accurate.',
                    webOnly: true,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _RoleCard(
                    icon: Icons.phone_android_rounded,
                    label: 'Students & Teachers',
                    title: 'Mobile experience',
                    body:
                        'Browse resources, scan QR codes, borrow items, and track returns.',
                    webOnly: false,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.webOnly,
  });

  final IconData icon;
  final String label;
  final String title;
  final String body;
  final bool webOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: webOnly ? const Color(0xFF102A43) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: webOnly ? null : Border.all(color: const Color(0xFFE5EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2C46),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: webOnly
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFEAF4F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: webOnly ? Colors.white : const Color(0xFF176B87),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: TextStyle(
              color: webOnly
                  ? const Color(0xFF94C9D9)
                  : const Color(0xFF176B87),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: webOnly ? Colors.white : const Color(0xFF102A43),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: webOnly
                  ? Colors.white.withValues(alpha: 0.78)
                  : const Color(0xFF627D98),
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalCta extends StatelessWidget {
  const _FinalCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176B87), Color(0xFF102A43)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ready for the next school day?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sign in to manage resources and borrowing operations.',
                style: TextStyle(color: Color(0xFFEAF4F7), height: 1.45),
              ),
            ],
          );
          final button = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF102A43),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: const Text('Sign in'),
          );
          return wide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [copy, button],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 20), button],
                );
        },
      ),
    );
  }
}
