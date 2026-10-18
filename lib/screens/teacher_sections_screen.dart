import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/section_model.dart';
import '../services/section_service.dart';

class TeacherSectionsScreen extends StatefulWidget {
  const TeacherSectionsScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.initialSectionIds,
    this.removalNotices = const [],
    this.sectionStatusNotices = const [],
  });

  final String teacherId;
  final String teacherName;
  final Set<String> initialSectionIds;
  final List<Map<String, dynamic>> removalNotices;
  final List<Map<String, dynamic>> sectionStatusNotices;

  @override
  State<TeacherSectionsScreen> createState() => _TeacherSectionsScreenState();
}

class _TeacherSectionsScreenState extends State<TeacherSectionsScreen> {
  final _service = SectionService();
  late Set<String> _selectedIds;
  List<SectionModel> _sections = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSectionIds};
    _loadSections();
  }

  Future<void> _loadSections() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(SectionService.collection)
        .get();
    if (!mounted) return;
    setState(() {
      _sections = snapshot.docs.map(SectionModel.fromFirestore).toList()
        ..sort((a, b) {
          final gradeA = int.tryParse(a.gradeLevel) ?? 999;
          final gradeB = int.tryParse(b.gradeLevel) ?? 999;
          final gradeComparison = gradeA.compareTo(gradeB);
          return gradeComparison == 0
              ? a.displayName.compareTo(b.displayName)
              : gradeComparison;
        });
      _loading = false;
    });
  }

  Future<void> _assignSections(List<String> sectionIds) async {
    setState(() => _saving = true);
    try {
      for (final id in sectionIds) {
        await _service.assignTeacher(
          sectionId: id,
          teacherId: widget.teacherId,
          teacherName: widget.teacherName,
        );
      }
      if (!mounted) return;
      setState(() => _selectedIds.addAll(sectionIds));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Handled sections added.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update sections: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddHandledSection() async {
    final available = _sections
        .where((section) => section.isActive && !section.isDeleted)
        .where((section) => !_selectedIds.contains(section.id))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All available sections are selected.')),
      );
      return;
    }
    final chosen = <String>{};
    final maxAdd = (5 - _selectedIds.length).clamp(1, available.length);
    final added = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        var count = 1;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Handled Sections'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: count,
                  decoration: const InputDecoration(
                    labelText: 'How many sections?',
                  ),
                  items: List.generate(
                    maxAdd,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} section(s)'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => count = value);
                  },
                ),
                const SizedBox(height: 12),
                ...available.map(
                  (section) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(section.displayName),
                    value: chosen.contains(section.id),
                    onChanged:
                        chosen.length >= count && !chosen.contains(section.id)
                        ? null
                        : (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                chosen.add(section.id);
                              } else {
                                chosen.remove(section.id);
                              }
                            });
                          },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: chosen.length == count
                    ? () => Navigator.pop(dialogContext, chosen.toList())
                    : null,
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
    if (added == null || !mounted) return;
    await _assignSections(added);
  }

  Future<void> _leave(SectionModel section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this section?'),
        content: Text(
          'You will be unassigned from ${section.displayName}. You can add it again later if it is still available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave Section'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _service.leaveSection(
        sectionId: section.id,
        teacherId: widget.teacherId,
      );
      if (!mounted) return;
      setState(() => _selectedIds.remove(section.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You left ${section.displayName}.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to leave section: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections Handled'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _showRemovalNotices,
            icon: Badge(
              isLabelVisible: widget.removalNotices.isNotEmpty,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Sections you handle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedIds.length} of 5 sections selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_selectedIds.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No handled sections yet. Add a section to start borrowing for your class.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ..._sections
                      .where((section) => _selectedIds.contains(section.id))
                      .map(
                        (section) => Card(
                          child: ListTile(
                            title: Text(section.displayName),
                            subtitle: Text(
                              section.isActive
                                  ? 'Borrow limit: ${section.maxActiveBorrowQuantity} item(s)'
                                  : '${section.isDeleted ? 'Deleted' : 'Inactive'}: ${section.inactiveReason.isEmpty ? 'Admin has not provided a reason.' : section.inactiveReason}',
                            ),
                            leading: CircleAvatar(
                              backgroundColor: section.isActive
                                  ? null
                                  : Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                              child: Icon(
                                section.isActive
                                    ? Icons.groups_3_outlined
                                    : Icons.warning_amber_outlined,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _saving ? null : () => _leave(section),
                              child: const Text('Leave'),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _showAddHandledSection,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Handled Section'),
                ),
              ],
            ),
    );
  }

  void _showRemovalNotices() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content:
            widget.removalNotices.isEmpty && widget.sectionStatusNotices.isEmpty
            ? const Text('No section assignment notifications.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...widget.sectionStatusNotices.reversed.map(
                      (notice) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(
                          '${notice['sectionName'] ?? 'A section'} was ${notice['status']?.toString().toLowerCase() ?? 'updated'}',
                        ),
                        subtitle: Text(
                          'Reason: ${notice['reason'] ?? 'No reason provided.'}',
                        ),
                      ),
                    ),
                    ...widget.removalNotices.reversed.map(
                      (notice) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline),
                        title: Text(
                          'Removed from ${notice['sectionName'] ?? 'a section'}',
                        ),
                        subtitle: Text(
                          'Reason: ${notice['reason'] ?? 'No reason provided.'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
