import 'package:flutter/material.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _aboutKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openLogin() => Navigator.of(context).pushNamed('/login');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: colors.surface,
              surfaceTintColor: colors.surface,
              titleSpacing: 20,
              title: Image.asset(
                'lib/assets/edutrack_logo/EduTrack_Rectangle_Logo-NoBackground.png',
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.school_outlined, color: colors.primary),
              ),
              actions: [
                if (MediaQuery.sizeOf(context).width >= 760) ...[
                  TextButton(
                    onPressed: () => _scrollTo(_featuresKey),
                    child: const Text('Features'),
                  ),
                  TextButton(
                    onPressed: () => _scrollTo(_aboutKey),
                    child: const Text('About System'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: FilledButton(
                      onPressed: _openLogin,
                      child: const Text('Portal Login'),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    tooltip: 'Features',
                    onPressed: () => _scrollTo(_featuresKey),
                    icon: const Icon(Icons.auto_awesome_outlined),
                  ),
                  IconButton(
                    tooltip: 'About System',
                    onPressed: () => _scrollTo(_aboutKey),
                    icon: const Icon(Icons.info_outline),
                  ),
                  IconButton(
                    tooltip: 'Portal Login',
                    onPressed: _openLogin,
                    icon: const Icon(Icons.login),
                  ),
                ],
              ],
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        _Hero(
                          onPortal: _openLogin,
                          onFeatures: () => _scrollTo(_featuresKey),
                        ),
                        const SizedBox(height: 80),
                        _SectionTitle(
                          key: _featuresKey,
                          eyebrow: 'SYSTEM FEATURES',
                          title: 'System Features',
                          description:
                              'How EduTrack PHS helps manage school equipment and books.',
                        ),
                        const SizedBox(height: 28),
                        const _FeaturesGrid(),
                        const SizedBox(height: 84),
                        _SectionTitle(
                          key: _aboutKey,
                          eyebrow: 'USER ROLES',
                          title: 'User Roles',
                          description:
                              'Designed for students, teachers, custodians, and admins.',
                        ),
                        const SizedBox(height: 28),
                        const _RolesGrid(),
                        const SizedBox(height: 76),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: colors.primaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 12,
                      children: [
                        Text(
                          'EduTrack PHS · High School Resource Management',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openLogin,
                          icon: const Icon(Icons.login),
                          label: const Text('Portal Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onPortal, required this.onFeatures});
  final VoidCallback onPortal;
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.surfaceContainerHighest],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'EDUTRACK PHS',
              style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'High School Resource Inventory & Borrowing System',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              'Check available equipment, submit borrow requests, and verify returns with photo proof.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                height: 1.45,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onPortal,
                icon: const Icon(Icons.login),
                label: const Text('Access Portal'),
              ),
              OutlinedButton(
                onPressed: onFeatures,
                child: const Text('View Features'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });
  final String eyebrow, title, description;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        eyebrow,
        style: TextStyle(
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Text(
        description,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _FeaturesGrid extends StatelessWidget {
  const _FeaturesGrid();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 850
          ? (constraints.maxWidth - 32) / 3
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: const _InfoCard(
              icon: Icons.inventory_2_outlined,
              title: 'Browse Available Equipment',
              body:
                  'Check real-time stock for textbooks, ICT devices, science kits, and lab tools.',
            ),
          ),
          SizedBox(
            width: width,
            child: const _InfoCard(
              icon: Icons.assignment_outlined,
              title: 'Simple Borrowing Process',
              body:
                  'Submit request forms online and track your active borrowings with due-date alerts.',
            ),
          ),
          SizedBox(
            width: width,
            child: const _InfoCard(
              icon: Icons.add_a_photo_outlined,
              title: 'Photo Return Verification',
              body:
                  'Upload a photo when returning items so Property Custodians can verify item condition.',
            ),
          ),
        ],
      );
    },
  );
}

class _RolesGrid extends StatelessWidget {
  const _RolesGrid();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 850
          ? (constraints.maxWidth - 32) / 3
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: const _InfoCard(
              icon: Icons.school_outlined,
              title: 'Students & Teachers',
              body:
                  'Search resources, request items, track due dates, and upload return photos.',
            ),
          ),
          SizedBox(
            width: width,
            child: const _InfoCard(
              icon: Icons.inventory_outlined,
              title: 'Property Custodians',
              body:
                  'Approve borrow requests, inspect return photo proof, and update stock counts.',
            ),
          ),
          SizedBox(
            width: width,
            child: const _InfoCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'ICT Coordinators / Admins',
              body:
                  'Manage user accounts, set role permissions, and view activity logs.',
            ),
          ),
        ],
      );
    },
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}
