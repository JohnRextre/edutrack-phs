import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/section_model.dart';
import '../services/section_service.dart';
import '../services/user_service.dart';

class AdminSectionsScreen extends StatefulWidget {
  const AdminSectionsScreen({super.key});

  @override
  State<AdminSectionsScreen> createState() => _AdminSectionsScreenState();
}

class _AdminSectionsScreenState extends State<AdminSectionsScreen> {
  final _service = SectionService();
  final _userService = UserService();
  final _searchController = TextEditingController();
  String _sortBy = 'grade';
  bool _ascending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SectionModel> _visibleSections(List<SectionModel> sections) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = sections.where((section) {
      return query.isEmpty ||
          section.displayName.toLowerCase().contains(query) ||
          section.gradeLevel.toLowerCase().contains(query);
    }).toList();
    filtered.sort((a, b) {
      final comparison = switch (_sortBy) {
        'grade' => _gradeSortValue(a).compareTo(_gradeSortValue(b)),
        'limit' => a.maxActiveBorrowQuantity.compareTo(
          b.maxActiveBorrowQuantity,
        ),
        'usage' => a.currentActiveBorrowQuantity.compareTo(
          b.currentActiveBorrowQuantity,
        ),
        'status' => a.isActive.toString().compareTo(b.isActive.toString()),
        _ => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      };
      if (comparison != 0) return _ascending ? comparison : -comparison;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return filtered;
  }

  int _gradeSortValue(SectionModel section) =>
      int.tryParse(section.gradeLevel.trim()) ?? 99;

  Future<void> _edit([SectionModel? section]) async {
    final name = TextEditingController(text: section?.name ?? '');
    final grade = TextEditingController(text: section?.gradeLevel ?? '');
    final existingGrade = section?.gradeLevel.trim() ?? '';
    final gradeOptions = List<String>.generate(6, (index) => '${index + 7}');
    final initialGrade = gradeOptions.contains(existingGrade)
        ? existingGrade
        : 'Others';
    if (initialGrade == 'Others') {
      grade.text = RegExp(r'^\d+$').hasMatch(existingGrade)
          ? existingGrade
          : '';
    }
    var selectedGrade = initialGrade;
    final limit = TextEditingController(
      text: (section?.maxActiveBorrowQuantity ?? 30).toString(),
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(section == null ? 'Add Section' : 'Edit Section'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedGrade,
                  decoration: const InputDecoration(labelText: 'Grade level *'),
                  items: [
                    ...gradeOptions.map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('Grade $value'),
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'Others',
                      child: Text('Others'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      selectedGrade = value;
                      if (value != 'Others') grade.text = value;
                      if (value == 'Others' &&
                          !RegExp(r'^\d+$').hasMatch(grade.text)) {
                        grade.clear();
                      }
                    });
                  },
                ),
                if (selectedGrade == 'Others')
                  TextFormField(
                    controller: grade,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Other grade level *',
                      hintText: 'Enter 1 to 12',
                    ),
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      return number == null || number < 1 || number > 12
                          ? 'Enter a whole number from 1 to 12'
                          : null;
                    },
                  ),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Section name *',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: limit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Maximum active borrow quantity *',
                  ),
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');
                    return number == null || number < 1
                        ? 'Enter a whole number greater than 0'
                        : null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _service.saveSection(
                    id: section?.id,
                    name: name.text,
                    gradeLevel: grade.text,
                    maxActiveBorrowQuantity: int.parse(limit.text.trim()),
                    isActive: section?.isActive ?? true,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Unable to save section: $error')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    // The dialog route may still be animating after showDialog completes.
    // Dispose controllers after that route has finished removing its fields.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      name.dispose();
      grade.dispose();
      limit.dispose();
    });
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Section saved.')));
    }
  }

  Future<void> _toggleStatus(SectionModel section) async {
    final reason = TextEditingController();
    if (section.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Set section inactive?'),
          content: TextField(
            controller: reason,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason *',
              hintText: 'Explain why this section is inactive.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => reason.text.trim().isEmpty
                  ? null
                  : Navigator.pop(dialogContext, true),
              child: const Text('Set Inactive'),
            ),
          ],
        ),
      );
      Future<void>.delayed(const Duration(milliseconds: 350), reason.dispose);
      if (confirmed != true) return;
    }
    try {
      await _service.setSectionStatus(
        id: section.id,
        isActive: !section.isActive,
        reason: reason.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${section.displayName} is now ${!section.isActive ? 'Active' : 'Inactive'}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update status: $error')),
        );
      }
    }
  }

  Future<void> _delete(SectionModel section) async {
    if (section.currentActiveBorrowQuantity > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This section cannot be deleted while it has active borrowed items. Deactivate it instead.',
          ),
        ),
      );
      return;
    }

    final confirmation = TextEditingController();
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Section?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete "${section.displayName}". Users assigned to it may need to be reassigned.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmation,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Type Delete to confirm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                hintText: 'Explain why this section is being deleted.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              if (confirmation.text.trim() == 'Delete' &&
                  reason.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      confirmation.dispose();
      reason.dispose();
    });
    if (confirmed != true) return;
    final deletionReason = reason.text.trim();

    try {
      await _service.deleteSection(id: section.id, reason: deletionReason);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Section deleted.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete section: $error')),
        );
      }
    }
  }

  void _showSectionMenu(SectionModel section) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Assigned teachers'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showAssignedTeachers(section);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit section'),
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(section);
              },
            ),
            ListTile(
              leading: Icon(
                section.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              title: Text(section.isActive ? 'Set Inactive' : 'Set Active'),
              onTap: () {
                Navigator.pop(sheetContext);
                _toggleStatus(section);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete section',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _delete(section);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignedTeachers(SectionModel section) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(SectionService.collection)
                .doc(section.id)
                .snapshots(),
            builder: (context, sectionSnapshot) {
              final currentSection = sectionSnapshot.data?.exists == true
                  ? SectionModel.fromFirestore(sectionSnapshot.data!)
                  : section;
              return StreamBuilder<
                List<QueryDocumentSnapshot<Map<String, dynamic>>>
              >(
                stream: _userService.watchTeachers(),
                builder: (context, snapshot) {
                  final assigned = currentSection.assignedTeachers;
                  final assignedIds = assigned
                      .map((teacher) => teacher['id'])
                      .toSet();
                  final teachers = snapshot.data ?? const [];
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Assigned Teachers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(section.displayName),
                          const SizedBox(height: 12),
                          if (assigned.isEmpty)
                            const Text(
                              'No teachers assigned to this section yet.',
                            ),
                          ...assigned.map(
                            (teacher) => ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(
                                teacher['name']?.toString() ?? 'Teacher',
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove teacher',
                                icon: const Icon(Icons.person_remove_outlined),
                                onPressed: () =>
                                    _removeTeacher(section, teacher),
                              ),
                            ),
                          ),
                          const Divider(),
                          OutlinedButton.icon(
                            onPressed:
                                !currentSection.isActive ||
                                    currentSection.isDeleted ||
                                    assigned.length >= 5
                                ? null
                                : () => _showAssignTeachers(
                                    currentSection,
                                    teachers,
                                    assignedIds,
                                  ),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: Text(
                              !currentSection.isActive ||
                                      currentSection.isDeleted
                                  ? 'Section is inactive'
                                  : assigned.length >= 5
                                  ? 'Maximum of 5 teachers assigned'
                                  : 'Assign teachers',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Future<void> _showAssignTeachers(
    SectionModel section,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers,
    Set<Object?> assignedIds,
  ) async {
    final available = teachers
        .where((teacher) => !assignedIds.contains(teacher.id))
        .toList();
    final maxSelectable = (5 - section.assignedTeachers.length).clamp(
      1,
      available.length,
    );
    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No available teacher to assign. All eligible teachers are already assigned to this section.',
            ),
          ),
        );
      }
      return;
    }
    final selected = <String>{};
    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        var count = 1;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Assign teachers'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: count,
                  decoration: const InputDecoration(
                    labelText: 'How many teachers?',
                  ),
                  items: List.generate(
                    maxSelectable,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} teacher(s)'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      count = value;
                      selected.removeWhere(
                        (id) => !available.any((teacher) => teacher.id == id),
                      );
                      while (selected.length > count) {
                        selected.remove(selected.last);
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                ...available.map(
                  (teacher) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      (teacher.data()['fullName'] ?? 'Teacher').toString(),
                    ),
                    value: selected.contains(teacher.id),
                    onChanged:
                        selected.length >= count &&
                            !selected.contains(teacher.id)
                        ? null
                        : (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selected.add(teacher.id);
                              } else {
                                selected.remove(teacher.id);
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
                onPressed: selected.length == count
                    ? () => Navigator.pop(dialogContext, selected.toList())
                    : null,
                child: const Text('Assign'),
              ),
            ],
          ),
        );
      },
    );
    if (chosen == null) return;
    try {
      for (final teacherId in chosen) {
        final teacher = teachers.firstWhere((item) => item.id == teacherId);
        await _service.assignTeacher(
          sectionId: section.id,
          teacherId: teacherId,
          teacherName: (teacher.data()['fullName'] ?? 'Teacher').toString(),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to assign teachers: $error')),
        );
      }
    }
  }

  Future<void> _removeTeacher(
    SectionModel section,
    Map<String, dynamic> teacher,
  ) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove assigned teacher?'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason *',
            hintText: 'Explain why this teacher is being removed.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isNotEmpty) Navigator.pop(context, true);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    final removalReason = reason.text.trim();
    Future<void>.delayed(const Duration(milliseconds: 350), reason.dispose);
    if (confirmed != true) return;
    await _service.removeTeacher(
      sectionId: section.id,
      sectionName: section.displayName,
      teacherId: teacher['id'].toString(),
      reason: removalReason,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section/Class Management'),
        actions: [
          IconButton(
            tooltip: 'Add section',
            onPressed: _edit,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<SectionModel>>(
        stream: _service.watchAllSections(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load sections: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sections = snapshot.data!;
          final visibleSections = _visibleSections(sections);
          if (sections.isEmpty) {
            return _EmptySections(onAdd: _edit);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBar(
                        controller: _searchController,
                        hintText: 'Search by grade level or section name...',
                        leading: const Icon(Icons.search),
                        trailing: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'Sort sections',
                      icon: const Icon(Icons.sort),
                      onSelected: (value) {
                        setState(() {
                          if (_sortBy == value) {
                            _ascending = !_ascending;
                          } else {
                            _sortBy = value;
                            _ascending = true;
                          }
                        });
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'grade',
                          child: Text('Grade level'),
                        ),
                        PopupMenuItem(value: 'name', child: Text('Name')),
                        PopupMenuItem(
                          value: 'limit',
                          child: Text('Borrow limit'),
                        ),
                        PopupMenuItem(
                          value: 'usage',
                          child: Text('Current usage'),
                        ),
                        PopupMenuItem(value: 'status', child: Text('Status')),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${visibleSections.length} of ${sections.length} section(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: visibleSections.isEmpty
                    ? const Center(child: Text('No matching sections found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: visibleSections.length,
                        itemBuilder: (context, index) {
                          final section = visibleSections[index];
                          final limit = section.maxActiveBorrowQuantity;
                          final usage = section.currentActiveBorrowQuantity;
                          final progress = limit > 0
                              ? (usage / limit).clamp(0.0, 1.0)
                              : 0.0;
                          return Card(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.groups_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                section.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        Chip(
                                          avatar: const Icon(
                                            Icons.groups_3_outlined,
                                            size: 16,
                                          ),
                                          label: Text('$usage / $limit'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Chip(
                                          label: Text(
                                            section.isDeleted
                                                ? 'Deleted'
                                                : section.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                          ),
                                          backgroundColor: section.isActive
                                              ? Colors.green.shade100
                                              : Colors.grey.shade300,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    if (!section.isActive &&
                                        section.inactiveReason.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reason: ${section.inactiveReason}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(value: progress),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Section actions',
                                onPressed: () => _showSectionMenu(section),
                                icon: const Icon(Icons.more_vert),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No sections yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a section and set its shared borrowing limit for students and teachers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create First Section'),
            ),
          ],
        ),
      ),
    );
  }
}
